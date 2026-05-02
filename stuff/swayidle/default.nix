{
  symlinkJoin,
  swayidle,
  makeWrapper,
}:
symlinkJoin {
  name = "swayidle";
  paths = [ swayidle ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/swayidle \
        --add-flags "-C ${./config}"
  '';
}
