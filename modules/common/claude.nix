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
  authorizedKey = "${keyOpts} ${keys.users.claude.ed25519}";
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

    # /run/current-system/sw/bin → nix store; sudo doesn't follow symlinks,
    # so rules pin sw/bin paths. NOEXEC blocks system()/popen() chains for
    # direct binaries; FRR/wg shell wrappers (router/claude.nix) need exec.
    # First-flag whitelisting bounds subcommand reach but cannot prevent
    # destructive flags appearing later in argv (e.g. --vacuum after -u);
    # for hard guarantees, wrap in a dedicated bin.
    security.sudo.extraConfig = ''
      Defaults:claude lecture=never, logfile=/var/log/sudo-claude.log

      Cmnd_Alias CLAUDE_LOGS = \
        /run/current-system/sw/bin/journalctl, \
        /run/current-system/sw/bin/journalctl --no-pager *, \
        /run/current-system/sw/bin/journalctl -u *, \
        /run/current-system/sw/bin/journalctl -k *, \
        /run/current-system/sw/bin/journalctl -f *, \
        /run/current-system/sw/bin/journalctl -n *, \
        /run/current-system/sw/bin/journalctl -e *, \
        /run/current-system/sw/bin/journalctl -r *, \
        /run/current-system/sw/bin/journalctl --since *, \
        /run/current-system/sw/bin/journalctl --grep *, \
        /run/current-system/sw/bin/journalctl --list-boots

      Cmnd_Alias CLAUDE_NETSTAT = \
        /run/current-system/sw/bin/ss, \
        /run/current-system/sw/bin/ss *

      Cmnd_Alias CLAUDE_NFT = \
        /run/current-system/sw/bin/nft list *, \
        /run/current-system/sw/bin/nft -j list *, \
        /run/current-system/sw/bin/nft -a list *, \
        /run/current-system/sw/bin/nft describe *

      Cmnd_Alias CLAUDE_IP = \
        /run/current-system/sw/bin/ip addr show, \
        /run/current-system/sw/bin/ip addr show *, \
        /run/current-system/sw/bin/ip route show, \
        /run/current-system/sw/bin/ip route show *, \
        /run/current-system/sw/bin/ip route get *, \
        /run/current-system/sw/bin/ip link show, \
        /run/current-system/sw/bin/ip link show *, \
        /run/current-system/sw/bin/ip neigh show, \
        /run/current-system/sw/bin/ip neigh show *, \
        /run/current-system/sw/bin/ip rule show, \
        /run/current-system/sw/bin/ip rule show *, \
        /run/current-system/sw/bin/ip -* addr show, \
        /run/current-system/sw/bin/ip -* addr show *, \
        /run/current-system/sw/bin/ip -* route show, \
        /run/current-system/sw/bin/ip -* route show *, \
        /run/current-system/sw/bin/ip -* link show, \
        /run/current-system/sw/bin/ip -* link show *, \
        /run/current-system/sw/bin/ip -* neigh show, \
        /run/current-system/sw/bin/ip -* neigh show *, \
        /run/current-system/sw/bin/ip -* rule show, \
        /run/current-system/sw/bin/ip -* rule show *

      Cmnd_Alias CLAUDE_DNS = \
        /run/current-system/sw/bin/resolvectl status, \
        /run/current-system/sw/bin/resolvectl status *, \
        /run/current-system/sw/bin/resolvectl statistics, \
        /run/current-system/sw/bin/resolvectl query *, \
        /run/current-system/sw/bin/resolvectl dns, \
        /run/current-system/sw/bin/resolvectl domain

      Cmnd_Alias CLAUDE_NETWORK = \
        /run/current-system/sw/bin/networkctl, \
        /run/current-system/sw/bin/networkctl status, \
        /run/current-system/sw/bin/networkctl status *, \
        /run/current-system/sw/bin/networkctl list, \
        /run/current-system/sw/bin/networkctl list *, \
        /run/current-system/sw/bin/networkctl lldp, \
        /run/current-system/sw/bin/networkctl lldp *

      Cmnd_Alias CLAUDE_TIME = \
        /run/current-system/sw/bin/chronyc tracking, \
        /run/current-system/sw/bin/chronyc sources, \
        /run/current-system/sw/bin/chronyc sources *, \
        /run/current-system/sw/bin/chronyc activity, \
        /run/current-system/sw/bin/chronyc clients, \
        /run/current-system/sw/bin/chronyc serverstats

      Cmnd_Alias CLAUDE_PCAP = \
        /run/current-system/sw/bin/tcpdump -i *, \
        /run/current-system/sw/bin/tcpdump -ni *, \
        /run/current-system/sw/bin/tcpdump -nni *, \
        /run/current-system/sw/bin/tcpdump -nn *, \
        /run/current-system/sw/bin/tcpdump -c *, \
        /run/current-system/sw/bin/tcpdump --list-interfaces

      claude ALL=(root) NOPASSWD,NOEXEC: CLAUDE_LOGS, CLAUDE_NETSTAT, \
        CLAUDE_NFT, CLAUDE_IP, CLAUDE_DNS, CLAUDE_NETWORK, CLAUDE_TIME, \
        CLAUDE_PCAP
    '';
  };

  darwin = {
    age.secrets.ssh-claude-ed25519 = {
      file = "${specialArgs.secretsCommon}/ssh-claude-ed25519.age";
      owner = user0.name;
      group = "staff";
      mode = "0400";
      path = "/Users/${user0.name}/.ssh/claude_ed25519";
    };

    age.secrets.ssh-claude-rsa = {
      file = "${specialArgs.secretsCommon}/ssh-claude-rsa.age";
      owner = user0.name;
      group = "staff";
      mode = "0400";
      path = "/Users/${user0.name}/.ssh/claude_rsa";
    };

    home-manager.users.${user0.name}.programs.ssh.matchBlocks."claude" = {
      match = "user claude";
      identityFile = [
        config.age.secrets.ssh-claude-ed25519.path
        config.age.secrets.ssh-claude-rsa.path
      ];
      extraOptions.IdentitiesOnly = "yes";
    };
  };
}
