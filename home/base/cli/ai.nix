{ pkgs, ... }:

{
  home.packages = with pkgs; [
    pi-coding-agent
    cursor-cli
    openspec
  ];

  programs = {
    opencode = {
      enable = true;
      package = pkgs.opencode;
      enableMcpIntegration = true;
      skills = {
        find-skills = ./skills/find-skills;
      };
      # web = {
      #   enable = true;
      #   extraArgs = [
      #     "--hostname"
      #     "0.0.0.0"
      #     "--port"
      #     "4096"
      #     "--mdns"
      #   ];
      # };
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
