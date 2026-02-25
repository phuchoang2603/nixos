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
            "163" = {
              # Set 'Option + N' for Show Notification Center
              enabled = true;
              value = {
                parameters = [
                  110
                  45
                  524288
                ];
                type = "standard";
              };
            };
            "36".enabled = false; # Show Desktop (F11)
            "64".enabled = false; # Spotlight Search (Cmd + Space)
            "65".enabled = false; # Finder Search (Cmd + Alt + Space)
            "184".enabled = false; # Default Screenshot
          };
        };
        "com.microsoft.edgemac" = {
          NSUserKeyEquivalents = {
            "Close Tab" = "^w";
            "Find..." = "^f";
            "New Window" = "^n";
            "New InPrivate Window" = "^$n";
            "New Tab" = "^t";
            "Open Location..." = "^l";
            "Refresh This Page" = "^r";
            "Reopen Closed Tab" = "^$t";
            "Actual Size" = "^0";
            "Zoom In" = "^=";
            "Zoom Out" = "^-";
          };
        };
      };

      screencapture = {
        target = "clipboard";
      };

      hitoolbox.AppleFnUsageType = "Change Input Source";

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
        TrackpadThreeFingerDrag = false;
        TrackpadThreeFingerHorizSwipeGesture = 0;
        TrackpadThreeFingerTapGesture = 0;
        TrackpadThreeFingerVertSwipeGesture = 0;
        Clicking = true;
        Dragging = true;
      };

      spaces = {
        spans-displays = true;
      };

      finder = {
        AppleShowAllFiles = false;
        AppleShowAllExtensions = true;
        _FXShowPosixPathInTitle = true;
        FXPreferredViewStyle = "clmv"; # column view
        FXRemoveOldTrashItems = true;
        CreateDesktop = false;
        NewWindowTarget = "Home";
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

      iCal = {
        CalendarSidebarShown = true;
        "TimeZone support enabled" = true;
        "first day of week" = "Monday";
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
