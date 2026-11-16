{
  lib,
  stdenvNoCC,
  fetchurl,
  patchutils,
  kmod,
  kernel,
}:
let
  buildHeaders = import ./build-headers.nix { inherit lib kernel kmod; };
  revision = "56e7bd30ddeaddc42128482aa311cab873aee7c9";
  moduleVersion = "surface-binned-${builtins.substring 0 7 revision}";
  binningPatch = fetchurl {
    url = "https://raw.githubusercontent.com/dmanresa-saes/surface-ipu6-cameras/${revision}/patches/ov5693-binned-no-mipictrl.patch";
    hash = "sha256-mATcZ+lGpvhe96uMGyFRUtFi631QbIzf390Lh6Q7J1U=";
  };

  # Reconstruct just these two files from the configured kernel, including its
  # linux-surface patches. The bridge is inspected only, never built/installed.
  patchedSource = stdenvNoCC.mkDerivation {
    pname = "ov5693-surface-source";
    version = "${kernel.version}-${builtins.substring 0 7 revision}";
    src = kernel.src;
    nativeBuildInputs = [ patchutils ];

    unpackPhase = ''
      runHook preUnpack
      mkdir source
      cd source
      tar -xf "$src" --strip-components=1 --wildcards \
        '*/drivers/media/i2c/ov5693.c' \
        '*/drivers/media/pci/intel/ipu-bridge.c'
      runHook postUnpack
    '';

    patchPhase = ''
      runHook prePatch
      for kernelPatch in ${lib.escapeShellArgs kernel.patches}; do
        filterdiff \
          --include='*/drivers/media/i2c/ov5693.c' \
          --include='*/drivers/media/pci/intel/ipu-bridge.c' \
          "$kernelPatch" > selected.patch
        if test -s selected.patch; then
          patch -p1 --fuzz=0 < selected.patch
        fi
      done

      grep -qx 'CONFIG_VIDEO_OV5693=m' ${kernel.configfile} || {
        echo 'ov5693-surface requires CONFIG_VIDEO_OV5693=m (not built in).' >&2
        exit 1
      }

      # Detect the actual patched source, not a kernel version threshold. Never
      # add legacy clock handling on top of Rimoli's upstream implementation.
      if grep -q 'V4L2_MBUS_CSI2_NONCONTINUOUS_CLOCK' drivers/media/i2c/ov5693.c && \
        grep -Eq 'OV5693_MIPI_CTRL00_CLOCK_LANE_GATE[[:space:]]+BIT\(5\)' drivers/media/i2c/ov5693.c; then
        grep -q 'clock-noncontinuous' drivers/media/pci/intel/ipu-bridge.c || {
          echo 'Incomplete upstream OV5693 clock-lane fix; inspect the kernel.' >&2
          exit 1
        }
        echo upstream > clock-lane-fix
      else
        if grep -Eq 'clock-noncontinuous|MIPI_CTRL00|0x4800' \
          drivers/media/i2c/ov5693.c drivers/media/pci/intel/ipu-bridge.c; then
          echo 'Unrecognized clock-lane handling; inspect before patching OV5693.' >&2
          exit 1
        fi
        patch -p1 --fuzz=0 < ${./clock-lane-bit5.patch}
        echo local-bit5 > clock-lane-fix
      fi

      # This variant contains no MIPI_CTRL00 write, including on newer kernels.
      patch -p1 --fuzz=0 < ${binningPatch}
      printf '\nMODULE_VERSION("${moduleVersion}");\n' >> drivers/media/i2c/ov5693.c
      runHook postPatch
    '';

    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp drivers/media/i2c/ov5693.c clock-lane-fix "$out/"
      cp ${./Makefile} "$out/Makefile"
      runHook postInstall
    '';
  };
in
kernel.stdenv.mkDerivation {
  pname = "ov5693-surface";
  version = "2026-10-26-${kernel.modDirVersion}";
  src = patchedSource;

  nativeBuildInputs = [ kmod ] ++ kernel.moduleBuildDependencies;
  hardeningDisable = [
    "pic"
    "format"
  ];
  dontConfigure = true;
  enableParallelBuilding = true;

  makeFlags = kernel.commonMakeFlags ++ [
    "KBUILD_OUTPUT=${buildHeaders}"
    "KDIR=${buildHeaders}"
    "KERNELRELEASE=${kernel.modDirVersion}"
  ];

  installPhase = ''
    runHook preInstall
    install -Dm444 ov5693.ko "$out/lib/modules/${kernel.modDirVersion}/updates/ov5693.ko"
    install -Dm444 ${./depmod.conf} "$out/etc/depmod.d/ov5693-surface.conf"
    install -Dm444 clock-lane-fix "$out/share/ov5693-surface/clock-lane-fix"
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    module="$out/lib/modules/${kernel.modDirVersion}/updates/ov5693.ko"
    test "$(modinfo -F vermagic "$module" | cut -d ' ' -f 1)" = '${kernel.modDirVersion}'
    test "$(modinfo -F version "$module")" = '${moduleVersion}'
    modinfo -p "$module" | grep -q '^binned_y_offset:'
    nm -u "$module" | awk '{print $NF}' | sort -u > actual-imports
    comm -23 actual-imports ${buildHeaders}/allowed-imports > unexpected-imports
    test ! -s unexpected-imports
    modinfo -F depends "$module" | tr ',' '\n' | tr '-' '_' | sort -u > actual-depends
    diff -u ${buildHeaders}/stock-depends actual-depends
    runHook postInstallCheck
  '';

  passthru = {
    inherit
      patchedSource
      binningPatch
      moduleVersion
      buildHeaders
      ;
    inherit (kernel) modDirVersion;
  };

  meta = {
    description = "Surface OV5693 front sensor with working 1296x972 2x2 binning";
    homepage = "https://github.com/dmanresa-saes/surface-ipu6-cameras";
    license = lib.licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
  };
}
