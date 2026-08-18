{
  symlinkJoin,
  neovim-unwrapped,
  makeWrapper,
  runCommandLocal,
  vimPlugins,
  lib,
  python3,
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

    # language specific plugins
    typst-preview-nvim
    lean-nvim
    Coqtail
    vim-loves-dafny
  ];

  pythonEnv = python3.withPackages(ps: [ ps.pynvim ]); # required by coqtail

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
      --add-flags "--cmd 'let g:python3_host_prog=\"${pythonEnv}/bin/python3\"'" \
      --add-flags "-u ${nvimConfigPath}/init.lua"
  '';
  meta.mainProgram = "nvim";
}
