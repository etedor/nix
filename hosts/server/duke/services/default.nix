{ ... }:

{
  imports = [
    ./acme.nix
    ./nfs.nix
    ./nginx.nix
    ./paperless.nix
    ./podman
    ./quadlink.nix
    ./radio
    ./restic
    ./samba.nix
    ./zfs.nix
  ];
}
