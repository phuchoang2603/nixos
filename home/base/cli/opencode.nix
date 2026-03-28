{ pkgs, ... }:

{
  programs = {
    opencode = {
      enable = true;
      package = pkgs.opencode;
      enableMcpIntegration = true;
      settings = {
        permission = {
          edit = "ask";
          bash = "ask";
        };
        keybinds = {
          messages_half_page_up = "{";
          messages_half_page_down = "}";
        };
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
