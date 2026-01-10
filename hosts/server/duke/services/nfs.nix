{ ... }:

{
  services.nfs.server = {
    enable = true;
    exports = ''
      /pool0/users/eric 10.0.8.32(rw,sync,no_subtree_check,no_root_squash)
      /pool0/media 10.0.8.32(rw,sync,no_subtree_check,no_root_squash)
    '';
  };

  networking.firewall.allowedTCPPorts = [ 2049 ];
}
