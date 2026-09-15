{ pkgs, ... }:

{
  home.packages = with pkgs; [
    pi-coding-agent
    cursor-cli
  ];

  programs = {
    t3code = {
      enable = true;
    };

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
