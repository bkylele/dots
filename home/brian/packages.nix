{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  neovimPlugins = with pkgs.vimPlugins; [
    vim-fugitive
    vim-dispatch
    undotree
    nvim-lspconfig
    nvim-surround
    no-neck-pain-nvim
    luasnip
    vim-snippets

    # Language-specific plugins.
    typst-preview-nvim
    lean-nvim
    Coqtail
    vim-loves-dafny
  ];

  pythonWithPynvim = pkgs.python3.withPackages (pythonPackages: [
    pythonPackages.pynvim
  ]);
in
{
  users.users.brian.packages = with pkgs; [
    # Configured applications use their native XDG config paths. None of these
    # packages are wrapped to inject configuration or command-line arguments.
    bash
    kitty
    neovim-unwrapped

    bc
    zoxide
    fzf
    htop
    libnotify
    nodejs
    claude-code
    codex
    pi-coding-agent
    wl-clipboard # Used by the Kakoune system-clipboard mapping.
    mpv
    # The explicitly selected KDE applications.
    kdePackages.dolphin
    kdePackages.kate
    kdePackages.spectacle
    vesktop
    slack
    xournalpp
    # zotero
    inputs.glide.packages.${pkgs.stdenv.hostPlatform.system}.default
    qutebrowser
    catppuccin-cursors.mochaDark
    scrcpy
    android-tools
    zoom-us
    vial
    kakoune

    # Neovim discovers this interpreter and its pynvim module from PATH.
    pythonWithPynvim
  ];

  # Neovim searches XDG_DATA_DIRS, including the system profile's share/nvim/site.
  environment.systemPackages = [
    (pkgs.runCommand "dots-neovim-plugins" { } ''
      mkdir -p "$out/share/nvim/site/pack/dots/start"
      ${lib.concatMapStringsSep "\n" (plugin: ''
        ln -s ${plugin} "$out/share/nvim/site/pack/dots/start/${lib.getName plugin}"
      '') neovimPlugins}
    '')
  ];
  environment.pathsToLink = [ "/share/nvim" ];
}
