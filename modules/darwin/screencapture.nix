{ user, ... }:

{
  system.defaults.screencapture = {
    disable-shadow = true;
    target = "file";
    location = "/Users/${user}/Pictures";
  };
}
