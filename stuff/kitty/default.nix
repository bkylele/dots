{
    symlinkJoin,
    kitty,
    makeWrapper,
}:
{
  packages.default = symlinkJoin {
    name = "kitty";
    paths = [ kitty ];
    nativeBuildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/kitty \
          --set KITTY_CONFIG_DIRECTORY ${./.}
    '';
  };
}
