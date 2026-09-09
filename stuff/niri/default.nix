{
  symlinkJoin,
  niri,
  makeWrapper,
  writeText,
}:
let
  config = writeText "niri-config.kdl" (
    builtins.replaceStrings
      [ "~/.config/niri/" ]
      [ "${./.}/" ]
      (builtins.readFile ./config.kdl)
  );
in
symlinkJoin {
  name = "niri-custom";
  paths = [ niri ];
  nativeBuildInputs = [ makeWrapper ];
  inherit (niri) meta passthru;
  postBuild = ''
    wrapProgram $out/bin/niri \
      --set NIRI_CONFIG ${config}

    rm $out/share/systemd/user/niri.service
    substitute ${niri}/share/systemd/user/niri.service $out/share/systemd/user/niri.service \
      --replace-fail "${niri}/bin/niri" "$out/bin/niri"
  '';
}
