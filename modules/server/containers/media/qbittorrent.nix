{ lab, pkgs, ... }:

let
  uid = "1000";
  gid = "100";
  state = "${lab.appdata}/qbittorrent";
  initialConfig = pkgs.writeText "qbittorrent.conf" ''
    [BitTorrent]
    Session\DefaultSavePath=/data/downloads/torrents/
    Session\TempPath=/data/downloads/torrents/incomplete/
    Session\TempPathEnabled=true

    [LegalNotice]
    Accepted=true

    [Preferences]
    Connection\UPnP=false
    Downloads\SavePath=/data/downloads/torrents/
    Downloads\TempPath=/data/downloads/torrents/incomplete/
    WebUI\Address=*
    WebUI\ServerDomains=${lab.fqdn "qbittorrent"};qbittorrent;localhost
  '';
in
{
  systemd.tmpfiles.rules = [
    "d ${state} 0750 ${uid} ${gid} -"
    "d ${state}/config 0750 ${uid} ${gid} -"
    "d ${state}/config/qBittorrent 0750 ${uid} ${gid} -"
    "C ${state}/config/qBittorrent/qBittorrent.conf 0640 ${uid} ${gid} - ${initialConfig}"
  ];

  networking.firewall.interfaces.ens18 = {
    allowedTCPPorts = [ 6881 ];
    allowedUDPPorts = [ 6881 ];
  };

  virtualisation.oci-containers.containers.qbittorrent = lab.mkContainer {
    image = "lscr.io/linuxserver/qbittorrent:latest";
    environment = {
      PUID = uid;
      PGID = gid;
      UMASK = "002";
      WEBUI_PORT = "8080";
      TORRENTING_PORT = "6881";
    };
    ports = [
      "6881:6881/tcp"
      "6881:6881/udp"
    ];
    volumes = [
      "${state}/config:/config:rw"
      "${lab.media}/downloads/torrents:/data/downloads/torrents:rw"
    ];
    traefik = {
      name = "qbittorrent";
      port = 8080;
    };
  };
}
