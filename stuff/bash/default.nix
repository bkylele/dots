{
  symlinkJoin,
  bash,
  makeWrapper,
}:
symlinkJoin {
  name = "bash";
  paths = [ bash ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/bash \
        --add-flags "--init-file ${./bashrc}"
  '';
}
