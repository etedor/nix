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

  # fileSystems."/" and swapDevices are provided by ./disko.nix

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
