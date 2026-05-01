{
  symlinkJoin,
  kitty,
  makeWrapper,
}:
symlinkJoin {
  name = "kitty-custom";
  paths = [ kitty ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/kitty \
        --set KITTY_CONFIG_DIRECTORY ${./.}
  '';
}
