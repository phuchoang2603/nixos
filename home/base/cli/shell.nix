{ pkgs, config, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    # Silence upcoming default change warning; keep legacy behavior.
    dotDir = config.home.homeDirectory;

    # Vi mode
    defaultKeymap = "viins";

    # History configuration
    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      ignoreAllDups = true;
      share = true;
    };

    # Shell aliases
    shellAliases = {
      # File operations
      ls = "eza -lh --group-directories-first --icons=auto";
      lt = "eza --tree --level=2";
      copy = "rclone copy --progress --multi-thread-streams=32";

      # Application shortcuts
      v = "nvim";
      g = "git";
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

    # Local variables (defined at top of .zshrc)
    localVariables = {
      # fzf-tab zstyles
      ZSH_FZF_TAB_SWITCH_GROUP = "'<' '>'";
    };

    # Plugins
    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
    ];

    # Completion initialization
    completionInit = ''
      fpath+=(${pkgs.zsh-completions}/share/zsh/site-functions)

      autoload -Uz compinit

      typeset _zcompdump_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
      typeset _zcompdump_file="$_zcompdump_dir/zcompdump-''${ZSH_VERSION}"
      mkdir -p "$_zcompdump_dir"

      if [[ -f "$_zcompdump_file" ]]; then
        compinit -C -d "$_zcompdump_file"
      else
        compinit -d "$_zcompdump_file"
      fi

      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path "$_zcompdump_dir"

      # Case insensitive completion
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

      # Enable group descriptions
      zstyle ':completion:*:descriptions' format '[%d]'

      # Enable filename colorizing
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"

      # Disable default menu for fzf-tab
      zstyle ':completion:*' menu no
    '';

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

      # KUBECONFIG - merge all kube config files
      export KUBECONFIG=$(find ~/.kube -name "*.yml" 2>/dev/null | tr '\n' ':' | sed 's/:$//')

      # kubectl completion
      if command -v kubectl &>/dev/null; then
        source <(kubectl completion zsh)
      fi

      # fzf-tab configuration
      zstyle ':fzf-tab:*' switch-group '<' '>'
      zstyle ':fzf-tab:complete:*' fzf-flags --preview-window hidden
      zstyle ':fzf-tab:*' menu no
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

  # Enable dircolors for LS_COLORS
  programs.dircolors.enable = true;
}
