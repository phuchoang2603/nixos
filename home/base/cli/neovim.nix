{ lib, ... }:

{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = false;
  };

  xdg.configFile = {
    "nvim/lua" = {
      source = ./nvim/lua;
      recursive = true;
    };
    "nvim/init.lua".source = ./nvim/init.lua;
    "nvim/.stylua.toml".source = ./nvim/.stylua.toml;
  };
}
