{ pkgs, lib, ... }:

{
  programs.git = {
    enable = true;
    userName = "felix";
    userEmail = "xuanphuc.a1gv@gmail.com";

    aliases = {
      co = "checkout";
      br = "branch";
      ci = "commit";
      st = "status";
    };

    extraConfig = {
      pull.rebase = true;
      init.defaultBranch = "main";
    };
  };
}
