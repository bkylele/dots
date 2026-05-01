{
  symlinkJoin,
  hyprlock,
  makeWrapper,
}:
symlinkJoin {
  name = "hyprlock";
  paths = [ hyprlock ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/hyprlock \
        --add-flags "--config ${./hyprlock.conf}"
  '';
}
