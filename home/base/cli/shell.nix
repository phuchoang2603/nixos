{ pkgs, ... }:

{
  programs = {
    # Zsh
    zsh = {
      enable = true;

      enableCompletion = true;
      completionInit = ''
        autoload -Uz compinit
        # Only regenerate the dump file once a day, or if it doesn't exist
        if [[ -n "''${ZDOTDIR:-''$HOME}/.zcompdump(#qN.m-1)" ]]; then
          compinit -C
        else
          compinit
        fi
      '';

      initContent = ''
        # Custom keybindings
        bindkey '^W' forward-word
        bindkey '^B' backward-delete-word
        bindkey '^E' end-of-line
        bindkey '^A' beginning-of-line
        bindkey '^U' kill-whole-line

        # Edit command line in editor
        bindkey '^X' edit-command-line
        autoload -Uz edit-command-line
        zle -N edit-command-line
      '';

      defaultKeymap = "viins";

      plugins = [
        {
          name = "zsh-autosuggestions";
          src = pkgs.zsh-autosuggestions;
          file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
        }
      ];

      syntaxHighlighting = {
        enable = true;
        highlighters = [
          "main"
          "brackets"
          "pattern"
        ];
      };

      sessionVariables = {
        TERM = "xterm-256color";
        KEYTIMEOUT = "1";
      };

      shellAliases = {
        # File operations
        lt = "eza --tree --level=2";
        copy = "rclone copy --progress --multi-thread-streams=32";

        # Application shortcuts
        v = "nvim";
        gaa = "git add --all";
        gcam = "git commit --all --message";
        d = "docker";
        dcp = "docker compose";
        lzg = "lazygit";
        lzd = "lazydocker";
        oc = "opencode";
        q = "pi --model github-copilot/gpt-5.4-mini -p";

        # Kubernetes
        k = "kubectl";
        kx = "kubie ctx";
        kn = "kubie ns";
        ke = "kubie edit";
        ka = "kubectl get all";
        h = "helm";
      };

      siteFunctions = {
        img2png = ''
          if [ -z "$1" ]; then
            echo "Usage: img2png <input_file>"
            return 1
          fi
          local input_file="$1"
          local file_stem="''${input_file%.*}"
          local output_file="''${file_stem}.png"
          magick "$input_file" "$output_file"
        '';

        tn = ''
          local session_name="$(basename "$PWD")"
          if tmux has-session -t "$session_name" 2>/dev/null; then
            tmux attach -t "$session_name"
          else
            tmux new -s "$session_name"
          fi
        '';
      };
    };

    # Carapace - command completion
    carapace = {
      enable = true;
      enableZshIntegration = true;
    };

    # Atuin - shell history
    atuin = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        enter_accept = false;
        keymap_mode = "auto";
        scroll_exits = false;
      };
    };

    # FZF - fuzzy finder
    fzf = {
      enable = true;
      enableZshIntegration = true;

      defaultCommand = "fd --type f --hidden --strip-cwd-prefix --exclude .git";
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
      ];

      fileWidgetCommand = "fd --type f --hidden --strip-cwd-prefix --exclude .git";
      fileWidgetOptions = [
        "--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
      ];

      changeDirWidgetCommand = "fd --type directory --hidden";
      changeDirWidgetOptions = [
        "--preview 'eza -1 --color=always {} || ls --color=always {}'"
      ];
    };

    # Zoxide - smart cd
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    # Bat - cat replacement
    bat = {
      enable = true;
    };

    # Eza - ls replacement
    eza = {
      enable = true;
      enableZshIntegration = true;
      icons = "auto";
      git = true;
      extraOptions = [
        "--long"
        "--header"
        "--group-directories-first"
        "--git"
      ];
    };

    # Starship - beautiful prompt
    starship = {
      enable = true;
      enableZshIntegration = true;

      settings = {
        add_newline = false;

        gcloud = {
          disabled = true;
        };

        aws = {
          disabled = true;
        };
      };
    };
  };
}
