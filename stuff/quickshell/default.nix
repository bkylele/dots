{
  symlinkJoin,
  quickshell,
  makeWrapper,
}:
symlinkJoin {
  name = "quickshell-custom";
  paths = [ quickshell ];
  nativeBuildInputs = [ makeWrapper ];
  meta.mainProgram = "quickshell";
  postBuild = ''
    wrapProgram $out/bin/quickshell \
      --add-flags "--path ${./.}"
    wrapProgram $out/bin/qs \
      --add-flags "--path ${./.}"

    mkdir -p $out/etc/xdg/autostart
    cat > $out/etc/xdg/autostart/quickshell.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Quickshell
Exec=$out/bin/quickshell
EOF
  '';
}
