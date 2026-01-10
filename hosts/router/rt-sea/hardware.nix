{
  lib,
  ...
}:

{
  imports = [ ];

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "sr_mod"
    "uhci_hcd"
    "virtio_blk"
    "virtio_pci"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/4151ef53-8161-45d9-8325-91d57a4aef9b";
    fsType = "ext4";
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/2db82174-acdd-41fa-80ed-223322ccc263"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  virtualisation.hypervGuest.enable = true;
}
