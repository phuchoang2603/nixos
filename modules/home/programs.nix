{ pkgs, lib, ... }:

{
  # Atuin - shell history
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
  };

  # FZF - fuzzy finder
  programs.fzf = {
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
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Bat - cat replacement
  programs.bat = {
    enable = true;
  };

  # Eza - ls replacement
  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
  };
}
