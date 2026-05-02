{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    daemon.settings.features.cdi = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
}
