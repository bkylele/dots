{
    symlinkJoin,
    makeWrapper,
    niri,
}:
let
in
symlinkJoin {
  name = "niri-custom";
  paths = [ niri ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/niri \
        --add-flags "--config  ${./config.kdl}"
  '';
}
