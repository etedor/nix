# disk layout for the RackNerd KVM VPS (virtio /dev/vda).
# GPT with a bios_grub partition for legacy BIOS boot, ext4 root, swap.
# disko owns fileSystems."/" and swapDevices — do not also set them in hardware.nix.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/vda";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          priority = 1;
          size = "1M";
          type = "EF02"; # BIOS boot partition (GRUB core.img)
        };
        swap = {
          priority = 2;
          size = "1G";
          content = {
            type = "swap";
          };
        };
        # 100% partition must be created last so fixed-size ones get their space
        root = {
          priority = 3;
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
