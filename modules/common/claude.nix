# claude code diagnostic account
# private key deployed via agenix to darwin hosts
{
  config,
  globals,
  lib,
  mkModule,
  pkgs,
  specialArgs,
  ...
}:

let
  keys = globals.keys;
  net = globals.networks;
  user0 = globals.users 0;

  keyOpts = lib.concatStringsSep "," [
    "from=\"${lib.concatStringsSep "," net.admin}\""
    "restrict"
    "pty"
  ];
  authorizedKey = "${keyOpts} ${keys.users.claude}";
in
mkModule {
  linux = {
    users.groups.claude = { };
    users.users.claude = {
      isNormalUser = true;
      group = "claude";
      hashedPassword = "!"; # locked
      shell = pkgs.bash;
      extraGroups = [ "systemd-journal" ];
      openssh.authorizedKeys.keys = [ authorizedKey ];
    };

    services.openssh.extraConfig = ''
      Match User claude
        AllowTcpForwarding no
        AllowAgentForwarding no
        X11Forwarding no
        PermitTunnel no
        AllowStreamLocalForwarding no
        GatewayPorts no
        PermitOpen none
    '';

    security.sudo.extraConfig = ''
      Defaults:claude lecture=never
    '';

    # NixOS symlinks /run/current-system/sw/bin → nix store;
    # sudo doesn't resolve these, so rules must use sw/bin paths.
    security.sudo.extraRules = [
      {
        users = [ "claude" ];
        commands =
          let
            # NOEXEC safe on direct binaries; NixOS shell wrappers
            # (wg, vtysh) need exec() — see router/claude.nix
            mkCmd = cmd: {
              command = cmd;
              options = [
                "NOPASSWD"
                "NOEXEC"
              ];
            };
            bin = "/run/current-system/sw/bin";
          in
          map mkCmd [
            "${bin}/chronyc"
            "${bin}/journalctl"
            "${bin}/networkctl"
            "${bin}/resolvectl"
            "${bin}/ss"

            # nft: read-only
            "${bin}/nft list *"
            "${bin}/nft -a list *"
            "${bin}/nft -j list *"
            "${bin}/nft describe *"

            # ip: show/get only — bare + wildcard variants
            # needed since sudoers * won't match empty args
            "${bin}/ip addr show"
            "${bin}/ip addr show *"
            "${bin}/ip route show"
            "${bin}/ip route show *"
            "${bin}/ip route get *"
            "${bin}/ip link show"
            "${bin}/ip link show *"
            "${bin}/ip neigh show"
            "${bin}/ip neigh show *"
            "${bin}/ip rule show"
            "${bin}/ip rule show *"
            "${bin}/ip -* addr show"
            "${bin}/ip -* addr show *"
            "${bin}/ip -* route show"
            "${bin}/ip -* route show *"
            "${bin}/ip -* link show"
            "${bin}/ip -* link show *"
            "${bin}/ip -* neigh show"
            "${bin}/ip -* neigh show *"
            "${bin}/ip -* rule show"
            "${bin}/ip -* rule show *"
          ];
      }
    ];

    security.wrappers.tcpdump = {
      source = "${pkgs.tcpdump}/bin/tcpdump";
      capabilities = "cap_net_raw+ep";
      owner = "root";
      group = "claude";
      permissions = "u+rx,g+rx,o-rwx";
    };
  };

  darwin = {
    age.secrets.claude-ssh-key = {
      file = "${specialArgs.secretsCommon}/claude-ssh-key.age";
      owner = user0.name;
      group = "staff";
      mode = "0400";
      path = "/Users/${user0.name}/.ssh/claude_ed25519";
    };

    home-manager.users.${user0.name}.programs.ssh.matchBlocks."claude-user" = {
      match = "user claude";
      identityFile = config.age.secrets.claude-ssh-key.path;
      extraOptions.IdentitiesOnly = "yes";
    };
  };
}
