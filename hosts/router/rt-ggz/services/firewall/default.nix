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
}
