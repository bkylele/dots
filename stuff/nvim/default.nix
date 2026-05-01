{
  symlinkJoin,
  neovim-unwrapped,
  makeWrapper,
  runCommandLocal,
  vimPlugins,
  lib,
}:
let
  nvimPlugins = with vimPlugins; [
    vim-fugitive
    vim-dispatch
    undotree
    nvim-lspconfig
    nvim-surround
    oil-nvim
    no-neck-pain-nvim
    luasnip
    vim-snippets
    lean-nvim
  ];

  packpath = runCommandLocal "packpath" { } ''
    mkdir -p $out/pack/nvim-custom/{start,opt}

    ${lib.concatMapStringsSep "\n" (
      plugin: "ln -vsfT ${plugin} $out/pack/nvim-custom/start/${lib.getName plugin}"
    ) nvimPlugins}
  '';

  nvimConfigPath = runCommandLocal "nvim-config" { } ''
    mkdir -p $out/
    cp -r ${./.}/* $out/
  '';
in
symlinkJoin {
  name = "neovim-custom";
  paths = [ neovim-unwrapped ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/nvim \
      --add-flags "--cmd 'set packpath^=${packpath}'" \
      --add-flags "--cmd 'set runtimepath^=${nvimConfigPath}'" \
      --add-flags "-u ${nvimConfigPath}/init.lua"
  '';
  meta.mainProgram = "nvim";
}
