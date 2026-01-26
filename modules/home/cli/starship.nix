{ pkgs, lib, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      add_newline = false;

      kubernetes = {
        disabled = false;
        symbol = "";
      };

      gcloud = {
        disabled = true;
      };

      aws = {
        disabled = true;
      };
    };
  };
}
