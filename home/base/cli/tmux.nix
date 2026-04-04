{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;

    # Basic settings
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";

    # Keybindings
    prefix = "C-a";
    keyMode = "vi";
    customPaneNavigationAndResize = true; # Enable hjkl navigation

    # Indexing
    baseIndex = 1; # Start window numbering at 1

    # Timing
    escapeTime = 0; # No delay for escape key

    # History
    historyLimit = 50000; # Scrollback buffer

    # Window behavior
    aggressiveResize = true; # Smart window resizing
    disableConfirmationPrompt = true; # No confirmation for kill-pane/window
    resizeAmount = 5; # Amount to resize panes

    # Focus events for better vim integration
    focusEvents = true;

    # Plugins
    plugins = with pkgs.tmuxPlugins; [
      sensible
      resurrect
      continuum
    ];

    extraConfig = ''
      # GENERAL SETTINGS
      set -g allow-passthrough on
      set -g detach-on-destroy off
      set -g renumber-windows on
      set -g set-clipboard on
      set -g status-position top

      # STATUS BAR
      set -g status-style fg=default,bg=default
      set -g status-left-length 30
      set -g status-right '#(gitmux "#{pane_current_path}")'
      set -g status-justify centre
      set -g window-status-format '#[fg=brightblack] #W '
      set -g window-status-current-format '#[fg=white,bold]#[fg=black,bg=white,bold] #W #[fg=white,bg=default]'

      # WINDOW NAMING
      set-option -g automatic-rename on
      set-option -g automatic-rename-format "#{pane_current_command}"

      # SPLIT PANES (keep current path)
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      # COPY MODE
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      # SESSION MANAGEMENT (via sesh)
      bind "o" run-shell "sesh connect \"$(
        sesh list --icons | fzf-tmux -p 80%,80% \
          --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
          --header 'Ctrl-a all | Ctrl-t tmux | Ctrl-z zoxide | Ctrl-x tmux kill' \
          --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' \
          --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
          --bind 'ctrl-z:change-prompt(📁  )+reload(sesh list -z --icons)' \
          --bind 'ctrl-x:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list -t --icons)' \
          --preview-window 'top:60%' \
          --preview 'sesh preview {}'
      )\""

      bind "g" display-popup \
        -d "#{pane_current_path}" \
        -w 80% \
        -h 90% \
        -E "lazygit"

      bind "y" display-popup \
        -d "#{pane_current_path}" \
        -w 80% \
        -h 90% \
        -E "lazydocker"

      bind -N "last-session (via sesh) " L run-shell "sesh last"
    '';
  };

  home.packages = with pkgs; [
    gitmux
    sesh
  ];
}
