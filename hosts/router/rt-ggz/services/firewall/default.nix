{ config, globals, ... }:

let
  filterForward = import ./rules/filter-forward.nix { inherit globals; };
  filterInput = import ./rules/filter-input.nix { inherit config globals; };
  manglePostrouting = import ./rules/mangle-postrouting.nix { };
  manglePrerouting = import ./rules/mangle-prerouting.nix { inherit globals; };
  natDnat = import ./rules/nat-dnat.nix { inherit globals; };
  natMasquerade = import ./rules/nat-masquerade.nix { inherit globals; };
  rawPrerouting = import ./rules/raw-prerouting.nix { };
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
