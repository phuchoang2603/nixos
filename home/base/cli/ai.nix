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
      web = {
        enable = true;
        extraArgs = [
          "--hostname"
          "0.0.0.0"
          "--port"
          "4096"
          "--mdns"
        ];
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
        plugin = [ "@rama_nigg/open-cursor@latest" ];
        provider = {
          cursor-acp = {
            name = "Cursor ACP";
            npm = "@ai-sdk/openai-compatible";

            options = {
              baseURL = "http://127.0.0.1:32124/v1";
            };

            models = {
              "cursor-acp/auto" = {
                name = "Auto";
              };

              "cursor-acp/claude-opus-4-7" = {
                name = "Claude 4.7 Opus";
              };

              "cursor-acp/gpt-5.5" = {
                name = "GPT-5.5";
              };
              "cursor-acp/gpt-5.4" = {
                name = "GPT-5.4";
              };
              "cursor-acp/gpt-5.4-mini" = {
                name = "GPT-5.4 Mini";
              };

              "cursor-acp/composer-2.5" = {
                name = "Composer 2.5";
              };
              "cursor-acp/composer-2.5-fast" = {
                name = "Composer 2.5 Fast";
              };
            };
          };
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
