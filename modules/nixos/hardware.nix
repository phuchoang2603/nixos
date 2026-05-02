{
  services = {
    # Bluetooth
    blueman.enable = true;

    # USB automounting
    udisks2.enable = true;

    # Set up udev rules for uinput
    udev.extraRules = ''
      KERNEL=="uinput", GROUP="input", MODE="0660"
    '';

    # Firmware updates
    fwupd.enable = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };
}
