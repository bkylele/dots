# Surface OV5693 front camera

`buggy` imports `modules/nixos/surface-ov5693-front-camera.nix`, which installs
the local `packages/ov5693-surface/` package through `boot.extraModulePackages`.
This supplies only the kernel-side OV5693 sensor fix, including the working
1296×972 2×2-binned mode. A usable desktop webcam may still need a compatible
IPU6/libcamera userspace pipeline. This configuration adds no camera services,
bridges, tuning files, HAL, PSYS, or replacement drivers for other sensors.

## Inspected kernel

The existing flake has two NixOS hosts: `buggy` (Surface desktop) and `wapol`
(server). The camera module is imported only by `buggy`.
The existing README and the machine used for build validation identify the
current desktop as a Surface Pro 8. The requested Surface Pro 7+ OV5693/IPU6
support uses the same sensor module, but a successful build here is not a
capture test on a Surface Pro 7+.

At the current lock-file pins, inspected on 2026-10-26:

| Item | Selection |
| --- | --- |
| Hardware module | `nixos-hardware.nixosModules.microsoft-surface-pro-intel` |
| `nixos-hardware` revision | `06f9ecaea5f64b6ff61cf42cb32f21621c4fa14a` |
| Kernel selection | `hardware.microsoft-surface.kernelVersion = "longterm"` (default) |
| Kernel package | `boot.kernelPackages.kernel`, `linux-6.19.8` |
| Kernel `modDirVersion` | `6.19.8` (the Nix package has no `-surface` release suffix) |
| linux-surface patch revision | `bf1921fc63f33d03a007fb38c4f88ff7e7bc1a55`, patches under `patches/6.19/` |
| Final generated kernel configuration | `CONFIG_VIDEO_OV5693=m` |
| Rimoli clock-lane fix | Absent from this kernel source and its linux-surface camera patches |

This is a linux-surface kernel despite the plain release name. The upstream
hardware module supplies the kernel and patches; this camera integration does
not change that kernel derivation or add `boot.kernelPatches`.

## Patches and upstream status

The package fetches
[`patches/ov5693-binned-no-mipictrl.patch`](https://github.com/dmanresa-saes/surface-ipu6-cameras/blob/56e7bd30ddeaddc42128482aa311cab873aee7c9/patches/ov5693-binned-no-mipictrl.patch)
from `dmanresa-saes/surface-ipu6-cameras` at commit
`56e7bd30ddeaddc42128482aa311cab873aee7c9`, with the fixed content hash
`sha256-mATcZ+lGpvhe96uMGyFRUtFi631QbIzf390Lh6Q7J1U=`.
It applies that exact binning-only patch, retaining its default
`binned_y_offset=2` (BGGR). The patch adds per-mode PLL/readout settings, window
geometry, vertical-flip handling, and a 30 fps default cap. It does not add
horizontal-flip polarity changes or a MIPI control write.

Fernando Rimoli's
[v5 clock-lane series](https://lore.kernel.org/linux-media/20260902142322.73523-1-fernandorimoli11@gmail.com/)
was [reported applied to media-committers `next` on 2026-09-11](https://lkml.iu.edu/hypermail/linux/kernel/2609.1/16802.html).
The sensor consumes `V4L2_MBUS_CSI2_NONCONTINUOUS_CLOCK` and changes only the
`BIT(5)` clock-lane gate through `cci_update_bits`; `ipu-bridge` supplies the
`clock-noncontinuous` property for the affected IPU6 devices. The selected
6.19.8 kernel predates that implementation. Binning remains downstream at the
pinned camera repository revision; landing the clock-lane series alone does
not replace the binned-mode fix.

For this older kernel, `clock-lane-bit5.patch` adds just a sensor-side
`cci_update_bits(..., CCI_REG8(0x4800), BIT(5), BIT(5), ...)` at stream-on.
This is a Surface-specific fallback, not a backport of the complete per-IPU
property series. It preserves all other bits and needs no bridge replacement.
The build inspects the configured patched sources, automatically omits this
fallback when it recognizes the upstream sensor and bridge implementation,
and fails on partial or unrecognized clock handling. It never applies the old
unconditional `MIPI_CTRL00 = 0x2d` write.

Remove the fallback file/branch when every supported configured kernel carries
the complete upstream clock-lane implementation. Remove the entire local
package, host import, module, and flake package/check outputs when the selected
kernel also contains the working binned PLL/readout/window/flip/VTS changes,
after verifying repeated 1296×972 captures on the target hardware. Merely
finding `1296`, `binning_x`, or a nominal binned format in the stock driver is
not sufficient: it already advertises binning without these working settings.

## Build and activate

From `/home/brian/dots`, make the new files visible to Git-based flake commands
(this stages only the newly added camera files, without committing them):

```bash
git add packages/ov5693-surface modules/nixos/surface-ov5693-front-camera.nix \
  docs/surface-ov5693-front-camera.md

# Focused module build; the package checks its vermagic, version and parameter.
nix build .#ov5693-surface --max-jobs 1 --cores 2
nix build .#checks.x86_64-linux.ov5693-surface-source \
  .#checks.x86_64-linux.ov5693-surface-precedence --no-link --max-jobs 1 --cores 2

# Exact configured ABI and produced file.
kver=$(nix eval --raw .#nixosConfigurations.buggy.config.boot.kernelPackages.kernel.modDirVersion)
test -f "result/lib/modules/$kver/updates/ov5693.ko"
modinfo "result/lib/modules/$kver/updates/ov5693.ko"
test "$(modinfo -F vermagic "result/lib/modules/$kver/updates/ov5693.ko" | cut -d ' ' -f 1)" = "$kver"
cat result/share/ov5693-surface/clock-lane-fix

sudo nixos-rebuild boot --flake .#buggy --max-jobs 1 --cores 2
sudo systemctl reboot
```

Use `path:.#ov5693-surface` (and the equivalent `path:.#checks...`) for checks
before staging new files. The integration changes to existing tracked Nix files
are visible even while unstaged. `boot` prepares the next generation; rebooting
ensures an already-loaded in-tree sensor module is replaced. There is no DKMS,
activation-time compilation, manual copying into `/lib/modules`, or live driver
reload step.

The package extracts the sensor and bridge `.c` files from `kernel.src`, applies
the relevant parts of `kernel.patches` with zero fuzz, and builds only
`obj-m := ov5693.o` with the kernel's compiler and common module flags. Its
separate `build-headers.nix` prepares the exact source, kernel patches and
generated configuration using `make modules_prepare`. It checks that
`olddefconfig`/preparation leave the configuration unchanged and that the
generated release equals `kernel.modDirVersion`. It never builds a kernel image
or the kernel's other modules, and does not depend on `kernel.dev`.

This works because this kernel has `CONFIG_MODVERSIONS=n` and
`CONFIG_RANDSTRUCT_NONE=y`. The preparer constructs a restricted, non-CRC
`Module.symvers` from the existing kernel's `System.map`, `modules.symbols` and
stock `ov5693.ko`. It permits only the stock driver's imports plus
`param_ops_int` for the new binning parameter, resolves the actual module
providers, and conservatively marks exports GPL-only. The stock module has no
namespace imports and the kernel enforces namespace imports. The package checks
the replacement's imports and dependencies against this stock metadata. It
does not weaken modpost errors or disable symbol checking. This prepared tree
is specific to OV5693, not a generic replacement for `kernel.dev`.

Preparation fails if symbol versioning, randomized layouts, namespace
requirements, or a changed configuration make these assumptions invalid. Such a
kernel would require its genuine matching development metadata; there is no
automatic full-kernel fallback. No kernel `vmlinux` is compiled merely to supply
optional BTF debug metadata for this sensor module.
Kbuild's `Skipping BTF generation ... due to unavailability of vmlinux` message
is expected here; it omits optional debug information, not sensor functionality.

The package installs
`lib/modules/<modDirVersion>/updates/ov5693.ko`. Its depmod configuration contains
`override ov5693 * updates`; NixOS merges that configuration into its aggregate
module tree before generating the index. The precedence check resolves
`ov5693` from that actual tree and compares it with this package's module.
The `share/ov5693-surface/clock-lane-fix` marker records `local-bit5` for the
inspected kernel, or `upstream` when the complete upstream fix is recognized.

Changing the camera patch rebuilds the extracted source and this one module,
not the kernel or prepared headers. A kernel update changes the source,
configuration, compiler/flags and export metadata dependency, preparing matching
headers and rebuilding this module for the newly selected kernel. The selected
kernel image and stock modules still need to exist, as for any system kernel
update; this package does not introduce a camera-specific kernel derivation.
The NixOS module retains the prepared tree through `system.extraDependencies`
for subsequent iterations across garbage collection. It does not retain or
request the full `kernel.dev` output.

## Post-boot checks

Check both the module selected on disk and the module actually loaded:

```bash
uname -r
modinfo -n ov5693
modinfo -F vermagic ov5693
modinfo -F version ov5693
modinfo -F srcversion ov5693
modinfo -p ov5693
lsmod | rg '^ov5693\b'
cat /sys/module/ov5693/version
cat /sys/module/ov5693/srcversion
cat /sys/module/ov5693/parameters/binned_y_offset
readlink -f /run/booted-system/kernel-modules/lib/modules/"$(uname -r)"/updates/ov5693.ko
sudo dmesg --color=never | rg -i 'ov5693|ipu6|ipu.bridge|int33be|csi.?2|dphy'
```

Expect an `updates/ov5693.ko` path resolving into the `ov5693-surface` package,
vermagic beginning with `uname -r`, the version `surface-binned-56e7bd3` in both
`modinfo` and sysfs, and `binned_y_offset` equal to `2`. `modinfo` alone describes
the file selected for a future load; the sysfs version confirms the loaded
replacement; compare `srcversion` too when present. If the sensor did not
autoload, `sudo modprobe ov5693` can test loading it, followed by another log
check.

Inspect the media graph and device nodes using a temporary diagnostic shell:

```bash
nix shell --inputs-from . nixpkgs#v4l-utils
v4l2-ctl --list-devices
for media in /dev/media*; do
  test -e "$media" || continue
  media-ctl -d "$media" -p
done
```

Find the `ov5693` sensor entity and its `/dev/v4l-subdevN` in the IPU6 ISYS graph;
node numbering and entity names can vary. Substitute the sensor node below:

```bash
v4l2-ctl -d /dev/v4l-subdevN --all
v4l2-ctl -d /dev/v4l-subdevN --list-subdev-mbus-codes pad=0
v4l2-ctl -d /dev/v4l-subdevN --get-subdev-fmt pad=0
```

With a compatible userspace pipeline configuring the matching sensor, receiver
and capture formats/links, test **1296×972 SBGGR10** at about 30 fps. A format
listing alone does not prove that the binned mode streams. Capture at least
twice, with the pipeline closed between attempts; confirm real frames, correct
colour/geometry, and no recurring FIFO overflow, frame-sync errors, D-PHY errors,
or capture timeouts. Recheck `dmesg` after capture. Do not assume a raw IPU6
`/dev/videoN` node is a desktop webcam or hardcode its number. Hardware capture
and desktop integration remain separate validation steps.
