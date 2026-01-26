{ pkgs, lib, ... }:

{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = false;

    extraPackages = with pkgs; [
      nodePackages.markdownlint-cli2
    ];

    initLua = lib.mkAfter ''
      require("config.lazy")
    '';
  };

  xdg.configFile."nvim/lua" = {
    source = ./nvim-config/lua;
    recursive = true;
  };

  xdg.configFile."nvim/stylua.toml".source = ./nvim-config/stylua.toml;
}
