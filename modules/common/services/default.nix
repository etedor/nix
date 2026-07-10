{ ... }:

{
  imports = [
    ./journald.nix
    ./msmtp.nix
    ./nscd.nix
    ./ssh
    ./time.nix
  ];
}
