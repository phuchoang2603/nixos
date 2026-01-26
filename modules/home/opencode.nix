{ pkgs, config, ... }:

{
  programs.opencode = {
    enable = true;
    package = pkgs.opencode;
    
    # Basic configuration
    settings = {
      "$schema" = "https://opencode.ai/config.json";
      theme = "opencode";
      
      # TUI settings
      tui = {
        scroll_acceleration = {
          enabled = true;
        };
      };
      
      # Permission settings
      permission = {
        edit = "ask";
        bash = "ask";
      };
      
      # Keybindings
      keybinds = {
        messages_half_page_up = "{";
        messages_half_page_down = "}";
      };
      
      # MCP servers (disabled)
      mcp = {
        "mcp-obsidian" = {
          type = "local";
          command = ["uvx" "mcp-obsidian"];
          enabled = false;
        };
        "context7" = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
          enabled = false;
        };
      };
    };
  };
}