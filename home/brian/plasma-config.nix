{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  atp = inputs.aerothemeplasma-nix.packages.${pkgs.stdenv.hostPlatform.system};
  # Snapshot of the installed Se7enAero assets, including icons and wallpaper.
  theme = pkgs.runCommand "dots-se7en-aero" { nativeBuildInputs = [ pkgs.xz ]; } ''
    mkdir -p "$out/share"
    tar -xJf ${./plasma-theme.tar.xz} -C "$out/share"
  '';
  settings = import ./plasma-settings.nix { inherit lib pkgs theme; };
  # Apps read colors from kdeglobals, not the scheme name, so append the Aero
  # scheme's color groups. Its [General]/[KDE] groups are already declared, and
  # declared [WM] entries (the title font) join the scheme's [WM] group.
  kdeglobals =
    value:
    pkgs.runCommand "kdeglobals"
      {
        settings = lib.generators.toINI { mkSectionName = lib.id; } (removeAttrs value [ "WM" ]);
        wm = lib.generators.toKeyValue { } (value.WM or { });
        passAsFile = [
          "settings"
          "wm"
        ];
      }
      ''
        cat "$settingsPath" > "$out"
        echo >> "$out"
        ${lib.getExe pkgs.gawk} -v wm="$wmPath" '
          /^\[/ { skip = ($0 == "[General]" || $0 == "[KDE]") }
          !skip { print }
          $0 == "[WM]" { while ((getline line < wm) > 0) print line }
        ' ${atp.color-scheme}/share/color-schemes/Aero.colors >> "$out"
      '';
  files = pkgs.linkFarm "dots-plasma-config" (
    lib.mapAttrsToList (name: value: {
      inherit name;
      # KConfig uses [parent][child] groups, rather than escaped INI brackets.
      path =
        if name == "kdeglobals" then
          kdeglobals value
        else
          pkgs.writeText (baseNameOf name) (lib.generators.toINI { mkSectionName = lib.id; } value);
    }) settings
  );
  apply = pkgs.writeShellApplication {
    name = "dots-plasma-apply";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
    ];
    text = ''
      config_dir="$HOME/.config"
      backup_dir="$HOME/.local/state/dots-plasma/backup"
      mkdir -p "$config_dir" "$backup_dir"
      # Names may include subdirectories, such as Kvantum/kvantum.kvconfig.
      while IFS= read -r -d "" name; do
        name=''${name#./}
        source="${files}/$name"
        target="$config_dir/$name"
        mkdir -p "$(dirname "$target")" "$(dirname "$backup_dir/$name")"
        if [[ -d "$target" ]]; then
          echo "dots-plasma: expected a file at $target" >&2
          exit 1
        fi
        if cmp -s "$source" "$target"; then continue; fi
        if [[ ( -e "$target" || -L "$target" ) && ! -e "$backup_dir/$name" && ! -L "$backup_dir/$name" ]]; then
          cp -a -- "$target" "$backup_dir/$name"
        fi
        temporary=$(mktemp "$(dirname "$target")/.dots-plasma.XXXXXXXX")
        install -m 600 "$source" "$temporary"
        mv -Tf -- "$temporary" "$target"
      done < <(cd ${files} && find -L . -type f -print0)

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
