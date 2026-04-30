# router-specific: FRR + WireGuard diagnostics
{
  pkgs,
  ...
}:

{
  users.users.claude.extraGroups = [ "frrvty" ];

  # NixOS shell wrappers (vtysh, wg) need exec() — no NOEXEC.
  # nfw is a read-only journalctl filter (modules/router/bin/nfw.sh).
  security.sudo.extraConfig = ''
    Cmnd_Alias CLAUDE_FRR = \
      /run/current-system/sw/bin/vtysh -c show *, \
      /run/current-system/sw/bin/vtysh -c list *

    Cmnd_Alias CLAUDE_WG = \
      /run/current-system/sw/bin/wg show, \
      /run/current-system/sw/bin/wg show *

    Cmnd_Alias CLAUDE_NFW = \
      /run/current-system/sw/bin/nfw, \
      /run/current-system/sw/bin/nfw *

    claude ALL=(root) NOPASSWD: CLAUDE_FRR, CLAUDE_WG, CLAUDE_NFW
  '';
}
