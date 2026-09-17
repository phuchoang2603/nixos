{
  pkgs,
  lib,
  config,
  ...
}:

let
  t3codePort = 3773;
  t3codePkg = config.programs.t3code.package;
  agentSkills = ./skills;

  t3CloudEnv = {
    T3CODE_RELAY_URL = "https://relay.t3.codes";
    T3CODE_CLERK_PUBLISHABLE_KEY = "pk_live_Y2xlcmsudDMuY29kZXMk";
    T3CODE_CLERK_CLI_OAUTH_CLIENT_ID = "hzxSgY2cH10sDU2r";
  };
in
{
  home.sessionVariables = t3CloudEnv;
  home.packages = with pkgs; [
    pi-coding-agent
    cursor-cli
    openspec
  ];

  programs = {
    t3code = {
      enable = true;
    };

    codex = {
      enable = true;
      enableMcpIntegration = true;
      skills = agentSkills;
      settings = {
        model_provider = "cliproxyapi";
        model_providers.cliproxyapi = {
          name = "CLIProxyAPI";
          base_url = "https://cliproxyapi.home.phuchoang.sbs/v1";
          wire_api = "responses";
          requires_openai_auth = false;
        };
      };
      context = ''
        - Prefer entering a repo's Nix devenv before work (`devenv allow`, `devenv shell`, or the project’s documented equivalent) whenever a devenv/flake/direnv setup exists.
        - If devenv cannot be used, say so briefly and continue with the closest available tools.
        - Use the Context7 MCP for current library/framework docs and best practices instead of relying on training data, whenever the task involves a public API, SDK, or framework.
      '';
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

  systemd.user.services.t3code = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "T3 Code headless server";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      Environment = [
        "T3CODE_RELAY_URL=${t3CloudEnv.T3CODE_RELAY_URL}"
        "T3CODE_CLERK_PUBLISHABLE_KEY=${t3CloudEnv.T3CODE_CLERK_PUBLISHABLE_KEY}"
        "T3CODE_CLERK_CLI_OAUTH_CLIENT_ID=${t3CloudEnv.T3CODE_CLERK_CLI_OAUTH_CLIENT_ID}"
      ];
      ExecStart = "${lib.getExe' t3codePkg "t3"} serve --host 0.0.0.0 --port ${toString t3codePort}";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
