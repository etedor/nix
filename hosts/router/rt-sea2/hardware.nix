{
  modulesPath,
  lib,
  ...
}:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "xen_blkfront"
    "vmw_pvscsi"
  ];
  boot.initrd.kernelModules = [ "nvme" ];

  fileSystems."/" = {
    device = "/dev/vda2";
    fsType = "ext4";
  };

  swapDevices = [
    { device = "/dev/vda3"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
