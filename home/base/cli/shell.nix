{ pkgs, ... }:

{
  programs = {
    # Zsh
    zsh = {
      enable = true;
      enableCompletion = true;

      # Vi mode
      defaultKeymap = "viins";

      # Shell aliases
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
        oc = "opencode --port";

        # Kubernetes
        kx = "kubectx";
        kn = "kubens";
        k = "kubectl";
        ka = "kubectl get all";
        h = "helm";
      };

      # Session variables
      sessionVariables = {
        TERM = "xterm-256color";
        KEYTIMEOUT = "1";
      };

      # Plugins
      plugins = [
        {
          name = "zsh-autosuggestions";
          src = pkgs.zsh-autosuggestions;
          file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
        }
      ];

      # Main zsh initialization content
      initContent = ''
        # Vi cursor shapes
        function zle-keymap-select {
          if [[ ''${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
            echo -ne '\e[1 q'
          elif [[ ''${KEYMAP} == main ]] || [[ ''${KEYMAP} == viins ]] || [[ -z ''${KEYMAP} ]] || [[ $1 = 'beam' ]]; then
            echo -ne '\e[5 q'
          fi
        }
        zle -N zle-keymap-select
        echo -ne '\e[5 q'

        function zle-line-init {
          echo -ne '\e[5 q'
        }
        zle -N zle-line-init

        # Custom keybindings
        bindkey '^W' forward-word
        bindkey '^B' backward-delete-word
        bindkey '^E' end-of-line
        bindkey '^A' beginning-of-line
        bindkey '^U' kill-whole-line
        bindkey '^X' edit-command-line

        # Edit command line in editor
        autoload -Uz edit-command-line
        zle -N edit-command-line

        # Optimized KUBECONFIG finder
        if [ -d "$HOME/.kube" ]; then
          export KUBECONFIG=$(find "$HOME/.kube" -maxdepth 1 -name "*.yml" 2>/dev/null | tr '\n' ':' | sed 's/:$//')
        fi
      '';

      # Custom functions as site functions (autoloadable)
      siteFunctions = {
        y = ''
          local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
          yazi "$@" --cwd-file="$tmp"
          if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            cd -- "$cwd"
          fi
          rm -f -- "$tmp"
        '';

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

    # Carapace
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
    };

    # Starship - beautiful prompt
    starship = {
      enable = true;
      enableZshIntegration = true;

      settings = {
        add_newline = false;

        kubernetes = {
          disabled = false;
          symbol = "";
        };

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
