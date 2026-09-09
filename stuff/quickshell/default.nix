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
  '';
}
