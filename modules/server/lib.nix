rec {
  nfsServer = "10.69.1.102";
  appdata = "/mnt/storage/container";
  media = "/mnt/storage/media";
  secrets = "${appdata}/secrets";
  domain = "home.phuchoang.sbs";
  tz = "America/New_York";
  proxyNetwork = "proxy";
}
