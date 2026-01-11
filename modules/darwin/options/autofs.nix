{
  config,
  globals,
  lib,
  ...
}:

let
  cfg = config.et42.device.autofs;

  # generate auto_nfs entries from mount config
  autoNfsEntries = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: mount:
      let
        opts = lib.concatStringsSep "," (
          [ "fstype=nfs" ] ++ mount.options
        );
      in
      "${mount.mountPoint} -${opts} ${mount.server}:${mount.remotePath}"
    ) cfg.mounts
  );

  # get unique parent directories for mount points
  parentDirs = lib.unique (
    lib.mapAttrsToList (name: mount: builtins.dirOf mount.mountPoint) cfg.mounts
  );
in
{
  options.et42.device.autofs = {
    enable = lib.mkEnableOption "autofs for NFS mounts";

    mounts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            server = lib.mkOption {
              type = lib.types.str;
              description = "NFS server hostname or IP";
            };
            remotePath = lib.mkOption {
              type = lib.types.str;
              description = "Remote path on NFS server";
            };
            mountPoint = lib.mkOption {
              type = lib.types.str;
              description = "Local mount point (under /System/Volumes/Data)";
            };
            options = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ "soft" "bg" "intr" ];
              description = "NFS mount options";
            };
          };
        }
      );
      default = { };
      description = "NFS mounts to configure via autofs";
    };
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.preActivation.text = lib.mkBefore ''
      if [ -f /etc/auto_master ] && [ ! -L /etc/auto_master ]; then
        echo "backing up /etc/auto_master..."
        mv /etc/auto_master /etc/auto_master.before-nix-darwin
      fi
    '';

    environment.etc."auto_master" = {
      text = ''
        #
        # Automounter master map
        #
        +auto_master
        /home			auto_home	-nobrowse,hidefromfinder
        /Network/Servers	-fstab
        /-			-static
        /-			auto_nfs	-nosuid,noowners
      '';
    };

    environment.etc."auto_nfs" = {
      text = autoNfsEntries;
    };

    system.activationScripts.postActivation.text = lib.mkAfter ''
      echo "creating autofs mount directories..."
      ${lib.concatMapStringsSep "\n" (dir: "mkdir -p ${dir}") parentDirs}
      echo "reloading automount..."
      automount -vc 2>/dev/null || true
    '';
  };
}
