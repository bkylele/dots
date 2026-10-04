{ lib, pkgs, ... }:
let
  # Snapshot of the installed Se7enAero assets, including icons and wallpaper.
  theme = pkgs.runCommand "dots-se7en-aero" { nativeBuildInputs = [ pkgs.xz ]; } ''
    mkdir -p "$out/share"
    tar -xJf ${./plasma-theme.tar.xz} -C "$out/share"
  '';
  settings = import ./plasma-settings.nix { inherit lib pkgs theme; };
  files = pkgs.linkFarm "dots-plasma-config" (
    lib.mapAttrsToList (name: value: {
      inherit name;
      # KConfig uses [parent][child] groups, rather than escaped INI brackets.
      path = pkgs.writeText name (
        lib.generators.toINI { mkSectionName = lib.id; } value
        + lib.optionalString (name == "kdeglobals") (builtins.readFile ./plasma-colors.ini)
      );
    }) settings
  );
  apply = pkgs.writeShellApplication {
    name = "dots-plasma-apply";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      config_dir="$HOME/.config"
      backup_dir="$HOME/.local/state/dots-plasma/backup"
      mkdir -p "$config_dir" "$backup_dir"
      for source in ${files}/*; do
        name=$(basename "$source")
        target="$config_dir/$name"
        if [[ -d "$target" ]]; then
          echo "dots-plasma: expected a file at $target" >&2
          exit 1
        fi
        if cmp -s "$source" "$target"; then continue; fi
        if [[ ( -e "$target" || -L "$target" ) && ! -e "$backup_dir/$name" && ! -L "$backup_dir/$name" ]]; then
          cp -a -- "$target" "$backup_dir/$name"
        fi
        temporary=$(mktemp "$config_dir/.dots-plasma.XXXXXXXX")
        install -m 600 "$source" "$temporary"
        mv -Tf -- "$temporary" "$target"
      done

      # Pin user-installed assets too: XDG_DATA_HOME otherwise shadows Nix's theme.
      for relative in plasma/look-and-feel/Se7enAero plasma/desktoptheme/Se7enAeroStyle \
        aurorae/themes/Se7enAero icons/Win11 color-schemes/Win7OS.colors \
        wallpapers/Windows7 wallpapers/Windows-7-Logon.png; do
        target="$HOME/.local/share/$relative"
        source="${theme}/share/$relative"
        if [[ -L "$target" && $(readlink "$target") == "$source" ]]; then continue; fi
        if [[ -e "$target" || -L "$target" ]]; then
          saved=$(mktemp -d "$backup_dir/theme.XXXXXXXX")
          mv -- "$target" "$saved/"
        fi
        mkdir -p "$(dirname "$target")"
        ln -s -- "$source" "$target"
      done
    '';
  };
in
{
  environment.systemPackages = [
    apply
    theme
  ];
  system.activationScripts.brian-plasma = {
    deps = [ "users" ];
    text = ''
      ${pkgs.util-linux}/bin/runuser -u brian -- ${lib.getExe apply}
    '';
  };

  # Reapply before Plasma starts: a running session may flush old settings after
  # a rebuild. Keep KDE's runtime files writable; the Nix generation is canonical.
  systemd.user.services.dots-plasma-config = {
    description = "Restore declarative Plasma settings";
    wantedBy = [ "graphical-session-pre.target" ];
    before = [ "graphical-session-pre.target" ];
    unitConfig.ConditionUser = "brian";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe apply;
    };
  };
}
