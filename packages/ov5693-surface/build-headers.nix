{
  lib,
  kernel,
  kmod,
}:
kernel.stdenv.mkDerivation {
  __structuredAttrs = true;
  pname = "ov5693-surface-build-headers";
  version = kernel.modDirVersion;
  inherit (kernel)
    src
    patches
    nativeBuildInputs
    ;
  env = kernel.env // {
    KBUILD_BUILD_USER = "nixbld";
    KBUILD_BUILD_HOST = "localhost";
  };

  # Prepare the existing configuration, never a kernel image or other drivers.
  # This intentionally supports only the non-versioned, non-randomized ABI used
  # by the selected Surface kernel. It is not a general kernel.dev replacement.
  hardeningDisable = [
    "bindnow"
    "format"
    "fortify"
    "stackprotector"
    "pic"
  ];
  makeFlags = kernel.commonMakeFlags;
  dontConfigure = true;
  enableParallelBuilding = true;

  postPatch = ''
    patchShebangs scripts
    unset src
  '';

  buildPhase = ''
    runHook preBuild
    grep -qx '# CONFIG_MODVERSIONS is not set' ${kernel.configfile} || {
      echo 'OV5693 header-only preparation needs CONFIG_MODVERSIONS=n; real Module.symvers is required otherwise. Refusing a full kernel build.' >&2
      exit 1
    }
    grep -qx 'CONFIG_RANDSTRUCT_NONE=y' ${kernel.configfile} || {
      echo 'OV5693 header-only preparation cannot reproduce a randomized kernel ABI.' >&2
      exit 1
    }
    grep -qx '# CONFIG_MODULE_ALLOW_MISSING_NAMESPACE_IMPORTS is not set' ${kernel.configfile}

    cp ${kernel.configfile} .config
    chmod u+w .config
    export KBUILD_BUILD_TIMESTAMP="$(date -u -d "@$SOURCE_DATE_EPOCH")"
    make "''${makeFlags[@]}" olddefconfig
    diff -u ${kernel.configfile} .config
    make -j"$NIX_BUILD_CORES" "''${makeFlags[@]}" modules_prepare
    diff -u ${kernel.configfile} .config
    test "$(cat include/config/kernel.release)" = '${kernel.modDirVersion}'

    stockModule=$(find ${lib.getOutput "modules" kernel}/lib/modules/${kernel.modDirVersion}/kernel/drivers/media/i2c \
      -maxdepth 1 -type f -name 'ov5693.ko*')
    case "$stockModule" in
      *.ko.xz) xz -dc "$stockModule" > stock-ov5693.ko ;;
      *.ko.zst) zstd -dc "$stockModule" > stock-ov5693.ko ;;
      *.ko.gz) gzip -dc "$stockModule" > stock-ov5693.ko ;;
      *.ko) cp "$stockModule" stock-ov5693.ko ;;
      *) echo 'Cannot locate exactly one stock OV5693 module.' >&2; exit 1 ;;
    esac
    test -z "$(${kmod}/bin/modinfo -F import_ns stock-ov5693.ko)"
    nm -u stock-ov5693.ko | awk '{print $NF}' > allowed-imports
    # The sole additional import introduced by the binned-mode module parameter.
    echo param_ops_int >> allowed-imports
    sort -u -o allowed-imports allowed-imports
    ${kmod}/bin/modinfo -F depends stock-ov5693.ko | tr ',' '\n' | \
      awk '{ normalized = $0; gsub(/-/, "_", normalized); print normalized, $0 }' > dependency-names
    awk '{print $1}' dependency-names | sort -u > stock-depends

    # With MODVERSIONS=n there are no CRCs to recover. Resolve only the stock
    # driver's imports (+ param_ops_int) against actual exports of this exact
    # kernel, keeping their module providers for modpost's dependency generation.
    # The stock module has no namespace imports and the kernel enforces them;
    # these imports therefore need no namespace. GPL-only marking is deliberately
    # conservative; this replacement is GPL, like the stock driver.
    awk -f ${./module-symbols.awk} \
      ${kernel}/System.map dependency-names \
      ${lib.getOutput "modules" kernel}/lib/modules/${kernel.modDirVersion}/modules.symbols \
      allowed-imports > Module.symvers
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/arch"
    cp -a Makefile Kbuild .config include scripts tools Module.symvers \
      allowed-imports stock-depends "$out/"
    cp -a arch/x86 "$out/arch/"
    runHook postInstall
  '';

  # Preserve prepared build helpers and metadata, as with kernel.dev.
  dontStrip = true;
  dontFixup = true;
}
