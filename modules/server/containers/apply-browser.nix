{ lab, ... }:

let
  data = "${lab.appdata}/apply-browser";
  build = lab.mkImage {
    name = "apply-browser";
    dockerfile = ./apply-browser/Dockerfile;
    context = ./apply-browser;
  };
in
{
  systemd.tmpfiles.rules = [ "d ${data}/profile 0700 root root -" ];

  systemd.services.apply-browser-image = build.service;

  virtualisation.oci-containers.containers.apply-browser = lab.mkContainer {
    inherit (build) image;
    pull = "never";
    volumes = [ "${data}/profile:/profile:rw" ];
    # NOTE: Both ports expose a browser logged into job portals with no authentication, so they stay on loopback; reach noVNC (6080) over an SSH tunnel.
    ports = [
      "127.0.0.1:9222:9222"
      "127.0.0.1:6080:6080"
    ];
    # NOTE: Chrome runs as root without its sandbox because the container has no user namespaces; the container is the isolation boundary.
    extraOptions = [
      "--init"
      "--shm-size=2g"
    ];
  };
}
