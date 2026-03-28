{ user, pkgs, ... }:

{
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

      screencapture = {
        target = "clipboard";
      };

      hitoolbox.AppleFnUsageType = "Change Input Source";

      spaces = {
        spans-displays = true;
      };

      iCal = {
        CalendarSidebarShown = true;
        "TimeZone support enabled" = true;
        "first day of week" = "Monday";
      };
    };

    keyboard = {
      enableKeyMapping = false;
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
