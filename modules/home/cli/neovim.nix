{ pkgs, lib, ... }:

{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = false;

    initLua = lib.mkAfter ''
      require("config.lazy")
    '';
  };

  xdg.configFile."nvim" = {
    source = ./nvim-config;
    recursive = true;
  };
}
