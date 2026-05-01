{
  symlinkJoin,
  hypridle,
  makeWrapper,
}:
symlinkJoin {
  name = "hypridle";
  paths = [ hypridle ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/hypridle \
        --add-flags "--config ${./hypridle.conf}"
  '';
}
