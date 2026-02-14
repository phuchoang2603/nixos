{
  pkgs,
  config,
  lib,
  ...
}:

{
  services.wlsunset = {
    enable = true;
    temperature = {
      day = 6500;
      night = 3000;
    };
    sunrise = "06:30";
    sunset = "18:00";
  };
}
