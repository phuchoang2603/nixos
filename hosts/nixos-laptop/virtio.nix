{
  pkgs,
  user,
  ...
}:

{
  virtualisation = {
    libvirtd = {
      enable = true;

      qemu = {
        swtpm.enable = true;
      };

    };

    spiceUSBRedirection.enable = true;
  };

  users = {
    users.${user} = {
      extraGroups = [
        "libvirtd"
        "kvm"
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    gnome-boxes
    dnsmasq
  ];
}
