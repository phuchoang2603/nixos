{ pkgs, ... }:

{
  home.packages = with pkgs; [
    pi-coding-agent
  ];

  programs = {
    opencode = {
      enable = true;
      package = pkgs.opencode;
      enableMcpIntegration = true;
      skills = {
        find-skills = ./skills/find-skills;
      };
      tui = {
        keybinds = {
          messages_half_page_up = "{";
          messages_half_page_down = "}";
        };
      };
      settings = {
        permission = {
          edit = "ask";
          bash = "ask";
        };
      };
    };

    codex = {
      enable = true;
      enableMcpIntegration = true;
      skills = {
        find-skills = ./skills/find-skills;
      };
    };

    mcp = {
      enable = true;
      servers = {
        "context7" = {
          url = "https://mcp.context7.com/mcp";
        };
      };
    };

  };
}
