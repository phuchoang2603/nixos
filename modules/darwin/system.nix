{ user, ... }:

{
  # System settings
  system = {
    stateVersion = 6;

    loginwindow = {
      GuestEnabled = false;
    };

    defaults = {
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
        expose-animation-duration = 0.15;
        show-recents = false;
        persistent-apps = [ ];
        tilesize = 30;
      };

      trackpad = {
        TrackpadRightClick = true;
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };

      finder = {
        AppleShowAllFiles = true;
        AppleShowAllExtensions = true;
        _FXShowPosixPathInTitle = true;
        FXPreferredViewStyle = "Nlsv"; # list view
        FXRemoveOldTrashItems = true;
        CreateDesktop = false;
        DisableAllAnimations = true;
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
    };

    primaryUser = user;
  };

  # Enable Touch ID for sudo
  security.pam.enableSudoTouchIdAuth = true;

  # Nix settings
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  # Garbage collection
  nix.gc = {
    automatic = true;
    interval = {
      Hour = 0;
      Minute = 0;
      Weekday = 7;
    };
    options = "--delete-older-than 7d";
  };
}
