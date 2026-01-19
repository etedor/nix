{ globals, ... }:

let
  user0 = globals.users 0;
  trust3 = globals.networks.ggz.trust3;
  opts = "rw,sync,no_subtree_check,no_root_squash";
in
{
  services.nfs.server = {
    enable = true;
    exports = ''
      /pool0/users/${user0.name} ${trust3}(${opts})
      /pool0/media ${trust3}(${opts})
    '';
  };

  networking.firewall.allowedTCPPorts = [ 111 2049 20048 ];
}
