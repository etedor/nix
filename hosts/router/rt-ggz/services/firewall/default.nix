{
  config,
  globals,
  ...
}:

let
  net = config.et42.router.networks;
  filterForward = import ./rules/filter-forward.nix { inherit config globals net; };
  filterInput = import ./rules/filter-input.nix { inherit config net; };
  manglePostrouting = import ./rules/mangle-postrouting.nix { };
  manglePrerouting = import ./rules/mangle-prerouting.nix { inherit net; };
  mangleForward = import ./rules/mangle-forward.nix { };
  natDnat = import ./rules/nat-dnat.nix { inherit config globals net; };
  natMasquerade = import ./rules/nat-masquerade.nix { inherit net; };
  rawPrerouting = import ./rules/raw-prerouting.nix { inherit net; };
in
{
  imports = [
    ./upnp.nix
  ];

  et42.router.nftables = {
    enable = true;

    mangleCounters = [
      {
        name = "game_traffic";
        comment = "Gaming traffic counter for CAKE bandwidth adjustment";
      }
    ];

    extraRawPreRoutingRules = rawPrerouting.rules;
    extraManglePreRoutingRules = manglePrerouting.rules;
    extraManglePostRoutingRules = manglePostrouting.rules;
    extraMangleForwardRules = mangleForward.rules;
    extraFilterInputRules = filterInput.rules;
    extraFilterForwardRules = filterForward.rules;
    dnat = natDnat.rules;
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
