{
  config,
  ...
}:

let
  wg = config.et42.router.wireguard;
  rt-sea = config.et42.router.peers.rt-sea;
  net = config.et42.router.networks;

  zone = {
    trust = [
      "wg0"
      "wg1"
    ];
    untrust = [ "ens3" ];
  };
  filterForward = import ./rules/filter-forward.nix { inherit net; };
  filterInput = import ./rules/filter-input.nix {
    inherit
      config
      net
      rt-sea
      wg
      zone
      ;
  };
  manglePostrouting = import ./rules/mangle-postrouting.nix { inherit wg; };
  natDnat = import ./rules/nat-dnat.nix { inherit zone; };
  natMasquerade = import ./rules/nat-masquerade.nix { inherit net; };
in
{
  et42.router.nftables = {
    enable = true;

    dnat = natDnat.rules;
    extraFilterForwardRules = filterForward.rules;
    extraFilterInputRules = filterInput.rules;
    extraManglePostRoutingRules = manglePostrouting.rules;
    masq = natMasquerade.rules;
  };

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;

    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;

    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;

    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;

    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
  };
}
