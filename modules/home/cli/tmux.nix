{ pkgs, lib, ... }:

{
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    mouse = true;
    prefix = "C-a";
    keyMode = "vi";
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 50000;
    terminal = "tmux-256color";

    extraConfig = ''
      set -g allow-passthrough on
      set -g detach-on-destroy off
      set -g renumber-windows on
      set -g set-clipboard on
      set -g status-position top
      set -g status-right '#(gitmux "#{pane_current_path}")'
      set -g status-style fg=default,bg=default
      set-option -g automatic-rename on
      set-option -g automatic-rename-format "#{b:pane_current_path}"
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind x kill-pane
      bind -T copy-mode-vi v send-keys -X begin-selection
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

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      resurrect
      continuum
    ];
  };
}
