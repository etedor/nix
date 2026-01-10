{ ... }:

{
  imports = [
    ./acme.nix
    ./nfs.nix
    ./nginx.nix
    ./paperless.nix
    ./podman
    ./radio
    ./restic
    ./samba.nix
    ./zfs.nix
  ];
}
