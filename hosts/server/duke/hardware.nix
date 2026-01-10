{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "ehci_pci"
    "megaraid_sas"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # stateVersion < 23.11 defaults swraid to true; we don't use md raid
  boot.swraid.enable = false;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/45c1c39c-b76f-4eee-80b2-a597f451d5a6";
    fsType = "btrfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/2F67-A622";
    fsType = "vfat";
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/28fbca1b-cb47-443e-90c1-ef0202545c5e"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
