{ pkgs, ... }:

{
  home.packages = with pkgs; [
    pi-coding-agent
    cursor-cli
  ];

  programs = {
    mcp = {
      enable = true;
      servers = {
        context7 = {
          url = "https://mcp.context7.com/mcp";
        };
      };
    };

  };
}
