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
    '';

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      resurrect
      continuum
    ];
  };
}
