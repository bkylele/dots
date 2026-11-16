{ config, ... }:
let
  ov5693-surface = config.boot.kernelPackages.callPackage ../../packages/ov5693-surface { };
in
{
  # Keep the linux-surface kernel unchanged. Only this external sensor module
  # depends on the local patches; kernel updates supply a new build ABI.
  boot.extraModulePackages = [ ov5693-surface ];

  # Retain the prepared build tree for subsequent sensor-only iterations.
  system.extraDependencies = [ ov5693-surface.buildHeaders ];

  # Also expose the exact host-specific package for focused build/ABI checks.
  system.build.ov5693-surface = ov5693-surface;
}
