# router-specific: FRR + WireGuard diagnostics
{
  pkgs,
  ...
}:

{
  users.users.claude.extraGroups = [ "frrvty" ];

  security.sudo.extraRules = [
    {
      users = [ "claude" ];
      commands =
        let
          # no NOEXEC — NixOS shell wrappers need exec()
          mkCmd = cmd: {
            command = cmd;
            options = [ "NOPASSWD" ];
          };
          bin = "/run/current-system/sw/bin";
        in
        map mkCmd [
          "${bin}/wg show *"
          "${bin}/vtysh -c show *"
          "${bin}/vtysh -c list *"
        ];
    }
  ];
}
