{ lab, ... }:

let
  uid = "1000";
  gid = "100";
  state = "${lab.appdata}/slskd";
in
{
  systemd.tmpfiles.rules = [
    "d ${state} 0750 ${uid} ${gid} -"
    "d ${state}/config 0750 ${uid} ${gid} -"
    "d ${state}/downloads 0750 ${uid} ${gid} -"
  ];

  networking.firewall.interfaces.ens18 = {
    allowedTCPPorts = [ 50300 ];
    allowedUDPPorts = [ 50300 ];
  };

  virtualisation.oci-containers.containers.slskd = lab.mkContainer {
    image = "slskd/slskd:latest";
    user = "${uid}:${gid}";
    ports = [
      "127.0.0.1:5030:5030"
      "50300:50300/tcp"
      "50300:50300/udp"
    ];
    volumes = [
      "${state}/config:/app:rw"
      "${state}/downloads:/downloads:rw"
    ];
    environment = {
      SLSKD_REMOTE_CONFIGURATION = "true";
      SLSKD_DOWNLOADS_DIR = "/downloads/complete";
      SLSKD_INCOMPLETE_DIR = "/downloads/incomplete";
      SLSKD_SLSK_LISTEN_PORT = "50300";
    };
  };
}
