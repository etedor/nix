{ globals, ... }:

let
  user0 = globals.users 0;
  trust3 = globals.networks.ggz.trust3;
  opts = "rw,sync,no_subtree_check,no_root_squash,nohide";
  rootOpts = "fsid=0,rw,sync,no_subtree_check,no_root_squash";
in
{
  services.nfs.server = {
    enable = true;
    exports = ''
      /pool0 ${trust3}(${rootOpts})
      /pool0/users ${trust3}(ro,sync,no_subtree_check,no_root_squash,nohide)
      /pool0/users/${user0.name} ${trust3}(${opts})
      /pool0/media ${trust3}(${opts})
    '';
  };

  services.nfs.settings = {
    nfsd.vers3 = false;
    nfsd.vers4 = true;
    nfsd."vers4.0" = true;
    nfsd."vers4.1" = true;
    nfsd."vers4.2" = true;
  };

  services.nfs.idmapd.settings = {
    General.Domain = globals.zone;
  };

  networking.firewall.allowedTCPPorts = [ 2049 ];
}
