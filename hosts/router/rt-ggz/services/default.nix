{ ... }:

{
  imports = [
    ./dhcp
    ./dns
    ./firewall
    ./journald.nix
    ./tftpd.nix
  ];
}
