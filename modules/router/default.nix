{
  pkgs,
  ...
}:

let
  nfw = pkgs.writeShellScriptBin "nfw" (builtins.readFile ./bin/nfw.sh);
  wg-mkclient = pkgs.writeShellScriptBin "wg-mkclient" (builtins.readFile ./bin/wg-mkclient.sh);
in
{
  imports = [
    ./atuin.nix
    ./options
  ];

  environment.systemPackages = with pkgs; [
    conntrack-tools
    wireguard-tools

    iftop
    termshark
    tshark
    qrencode

    flent
    fping
    netperf

    nfw
    wg-mkclient
  ];

  boot.kernel.sysctl."net.ipv4.ip_forward" = "1";
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = "1";
}
