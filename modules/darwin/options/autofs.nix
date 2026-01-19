{
  config,
  globals,
  lib,
  ...
}:

let
  cfg = config.et42.device.autofs;

  # generate mount entries based on fstype
  mkMountEntry = name: mount:
    let
      fstype = mount.fstype or "nfs";
      opts = lib.concatStringsSep "," (
        [ "fstype=${fstype}" ] ++ mount.options
      );
      remote =
        if fstype == "smbfs" then
          "://${mount.user}@${mount.server}/${mount.share}"
        else
          "${mount.server}:${mount.remotePath}";
    in
    "${mount.mountPoint} -${opts} ${remote}";

  autoEntries = lib.concatStringsSep "\n" (
    lib.mapAttrsToList mkMountEntry cfg.mounts
  );

  mountDirs = lib.mapAttrsToList (name: mount: mount.mountPoint) cfg.mounts;
in
{
  options.et42.device.autofs = {
    enable = lib.mkEnableOption "autofs for network mounts";

    mounts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            fstype = lib.mkOption {
              type = lib.types.enum [ "nfs" "smbfs" ];
              default = "nfs";
              description = "Filesystem type (nfs or smbfs)";
            };
            server = lib.mkOption {
              type = lib.types.str;
              description = "Server hostname or IP";
            };
            # NFS options
            remotePath = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Remote path on NFS server";
            };
            # SMB options
            share = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "SMB share name";
            };
            user = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "SMB username";
            };
            password = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "SMB password (stored in /etc/auto_nfs, root-only readable)";
            };
            mountPoint = lib.mkOption {
              type = lib.types.str;
              description = "Local mount point";
            };
            options = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Mount options";
            };
          };
        }
      );
      default = { };
      description = "Network mounts to configure via autofs";
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
      text = autoEntries;
    };

    system.activationScripts.postActivation.text = lib.mkAfter ''
      echo "creating autofs mount directories..."
      ${lib.concatMapStringsSep "\n" (dir: "mkdir -p ${dir}") mountDirs}
      echo "reloading automount..."
      automount -vc 2>/dev/null || true
    '';
  };
}
