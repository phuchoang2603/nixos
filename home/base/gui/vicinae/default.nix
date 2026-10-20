{ ... }:

{
  imports = [
    ./extensions.nix
    ./snippets.nix
    ./darwin.nix
    ./linux.nix
  ];

  programs.vicinae.settings = {
    input_server.enabled = true;
    tray.enabled = false;
    close_on_focus_loss = true;
    search_files_in_root = false;
    pop_to_root_on_close = true;
    consider_preedit = true;
    favorites = [
      "clipboard:history"
      "snippets:manage"
      "files:search"
      "core:search-emojis"
    ];
    global_shortcuts.toggle = "alt+space";
    providers = {
      calculator.entrypoints.history.shortcut = "alt+c";
      clipboard.entrypoints.history.shortcut = "alt+v";
      clipboard.preferences.evictionThreshold = "604800";
      files.entrypoints.search.shortcut = "alt+f";
      wm.entrypoints.switch-windows.shortcut = "alt+w";
    };
  };
}
