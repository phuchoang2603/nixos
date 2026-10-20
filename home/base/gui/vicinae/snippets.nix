{
  config,
  pkgs,
  lib,
  ...
}:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  jsonFormat = pkgs.formats.json { };
  snippetsFile =
    if isDarwin then
      "${config.home.homeDirectory}/.local/share/vicinae/snippets/snippets.json"
    else
      "${config.xdg.dataHome}/vicinae/snippets/snippets.json";
  managedSnippets = jsonFormat.generate "vicinae-managed-snippets.json" (
    map
      (snippet: {
        id = "snp_nix_${snippet.id}";
        inherit (snippet) name;
        createdAt = 0;
        data.text = snippet.text;
        expansion = {
          inherit (snippet) keyword;
          apps = [ ];
          word = false;
        };
      })
      [
        {
          id = "linkedin";
          name = "LinkedIn";
          keyword = ";lkd";
          text = "https://www.linkedin.com/in/phuchoang2603/";
        }
        {
          id = "github";
          name = "GitHub";
          keyword = ";gh";
          text = "https://github.com/phuchoang2603";
        }
        {
          id = "phone";
          name = "Phone";
          keyword = ";phone";
          text = "8136097656";
        }
        {
          id = "email";
          name = "Email";
          keyword = ";email";
          text = "xuanphuc.a1gv@gmail.com";
        }
        {
          id = "name";
          name = "Name";
          keyword = ";name";
          text = "Felix Hoang";
        }
      ]
  );
  syncSnippets = pkgs.writeShellApplication {
    name = "vicinae-sync-snippets";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = ''
      snippets_file=$1
      umask 077
      mkdir -p "$(dirname "$snippets_file")"
      temporary_file=$(mktemp "$(dirname "$snippets_file")/.snippets.XXXXXX")
      trap 'rm -f "$temporary_file"' EXIT
      {
        if [[ -e "$snippets_file" ]]; then
          cat "$snippets_file"
        else
          printf '[]\n'
        fi
      } | jq --slurpfile managed ${managedSnippets} '
        if type != "array" then error("Expected a snippet array") else . end
        | $managed[0] as $desired
        | [ .[] | select(. as $snippet | all($desired[];
            .id != $snippet.id and .expansion.keyword != $snippet.expansion.keyword
          )) ] + $desired
      ' > "$temporary_file"
      if ! cmp -s "$snippets_file" "$temporary_file"; then
        mv "$temporary_file" "$snippets_file"
      fi
    '';
  };
  startDarwinVicinae = pkgs.writeShellScript "start-vicinae" ''
    set -eu
    ${lib.getExe syncSnippets} ${lib.escapeShellArg snippetsFile}
    exec /usr/bin/open -g -W -a ${lib.escapeShellArg "${config.home.homeDirectory}/${config.targets.darwin.copyApps.directory}/Vicinae.app"} \
      --env "VICINAE_NODE_BIN=$VICINAE_NODE_BIN" \
      --env "VICINAE_OVERRIDES=$VICINAE_OVERRIDES" \
      --env "PATH=$PATH"
  '';
in
{
  config = lib.mkMerge [
    {
      programs.vicinae.settings.providers.snippets = {
        preferences.enabled = true;
        entrypoints.manage.shortcut = "alt+s";
      };
    }
    (lib.mkIf isDarwin {
      launchd.agents.vicinae.config.ProgramArguments = [ "${startDarwinVicinae}" ];
    })
    (lib.mkIf (!isDarwin) {
      systemd.user.services.vicinae.Service.ExecStartPre = [
        "${lib.getExe syncSnippets} ${lib.escapeShellArg snippetsFile}"
      ];
    })
  ];
}
