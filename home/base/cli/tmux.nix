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
      yank
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
      set -g status-left-length 21
      set -g status-right '#(gitmux "#{pane_current_path}")'
      set -g status-justify centre
      set -g window-status-format '#[fg=brightblack]#W'
      set -g window-status-current-format '#[fg=cyan,bold,underscore]#W'

      # WINDOW NAMING
      # Automatically rename window to command name instead of current path
      set-option -g automatic-rename on
      set-option -g automatic-rename-format "#{pane_current_command}"

      # SPLIT PANES (keep current path)
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      # COPY MODE
      bind -T copy-mode-vi v send-keys -X begin-selection

      # SESSION MANAGEMENT (via sesh)
      bind "o" run-shell "sesh connect \"$(
        sesh list --icons | fzf-tmux -p 80%,80% \
          --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
          --header 'Alt-a all | Alt-t tmux | Alt-z zoxide | Alt-x tmux kill | Alt-f find' \
          --bind 'tab:down,btab:up' \
          --bind 'alt-a:change-prompt(⚡  )+reload(sesh list --icons)' \
          --bind 'alt-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
          --bind 'alt-z:change-prompt(📁  )+reload(sesh list -z --icons)' \
          --bind 'alt-x:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list -t --icons)' \
          --bind 'alt-f:change-prompt(🔎  )+reload(fd -d 2 -t d . ~/repos/)' \
          --preview-window 'top:60%' \
          --preview 'sesh preview {}'
      )\""

      bind -N "last-session (via sesh) " L run-shell "sesh last"
    '';
  };

  home.packages = with pkgs; [
    gitmux
    sesh
  ];
}
