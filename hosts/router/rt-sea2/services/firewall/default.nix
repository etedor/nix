{
  config,
  globals,
  ...
}:

let
  filterForward = import ./rules/filter-forward.nix { inherit globals; };
  filterInput = import ./rules/filter-input.nix { inherit config globals; };
  natDnat = import ./rules/nat-dnat.nix { inherit globals; };
  natMasquerade = import ./rules/nat-masquerade.nix { inherit globals; };
in
{
  et42.router.nftables = {
    enable = true;

    dnat = natDnat.rules;
    extraFilterForwardRules = filterForward.rules;
    extraFilterInputRules = filterInput.rules;
    masq = natMasquerade.rules;
  };
}
