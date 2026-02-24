{ user, pkgs, ... }:

{
  # System settings
  system = {
    stateVersion = 6;

    defaults = {
      loginwindow = {
        GuestEnabled = false;
      };

      controlcenter = {
        BatteryShowPercentage = true;
        NowPlaying = false;
      };

      CustomUserPreferences = {
        "com.apple.symbolichotkeys" = {
          AppleSymbolicHotKeys = {
            "64" = {
              # Disable 'Cmd + Space' for Spotlight Search
              enabled = false;
            };
            "65" = {
              # Disable 'Cmd + Alt + Space' for Finder search window
              enabled = false;
            };
          };
        };
      };

      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.0;
        expose-animation-duration = 0.15;
        expose-group-apps = true;
        show-recents = false;
        persistent-apps = [ ];
        tilesize = 30;
      };

      trackpad = {
        TrackpadRightClick = true;
        Clicking = true;
      };

      spaces = {
        spans-displays = true;
      };

      finder = {
        AppleShowAllFiles = true;
        AppleShowAllExtensions = true;
        _FXShowPosixPathInTitle = true;
        FXPreferredViewStyle = "clmv"; # column view
        FXRemoveOldTrashItems = true;
        CreateDesktop = false;
        NewWindowTarget = "Desktop";
        ShowPathbar = true;
        ShowStatusBar = true;
      };

      NSGlobalDomain = {
        AppleICUForce24HourTime = true;
        AppleInterfaceStyle = "Dark";
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;
        InitialKeyRepeat = 20;
        KeyRepeat = 2;
        NSUseAnimatedFocusRing = false;
        NSDocumentSaveNewDocumentsToCloud = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticWindowAnimationsEnabled = false;
      };
    };

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
      swapLeftCtrlAndFn = true;
    };

    primaryUser = user;
  };

  users.users.${user} = {
    name = user;
    home = "/Users/${user}";
  };

  security = {
    pam.services.sudo_local.touchIdAuth = true;
    sudo.extraConfig = "${user}    ALL = (ALL) NOPASSWD: ALL";
  };

  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-mono
    noto-fonts
    noto-fonts-color-emoji
  ];
}
