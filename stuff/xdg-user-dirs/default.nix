{
  symlinkJoin,
  xdg-user-dirs,
  makeWrapper,
}:
let
  confpath = runCommandLocal "xdg-config" { } ''
    mkdir -p $out/
    cp ${./user-dirs.dirs} $out/
  '';
in
symlinkJoin {
  name = "xdg-user-dirs";
  paths = [ xdg-user-dirs ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/bash \
        --set "XDG_CONFIG_HOME ${confpath}"
  '';
}
