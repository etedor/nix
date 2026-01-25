{
  config,
  globals,
  lib,
  pkgs,
  ...
}:

let
  nfw = pkgs.writeShellScriptBin "nfw" (builtins.readFile ./bin/nfw.sh);

  hostname = config.networking.hostName;
  dnsServer = globals.routers.${hostname}.interfaces.lo0;
  zone = globals.zone;

  wg-mkclient = pkgs.writeShellScriptBin "wg-mkclient" ''
    #!/usr/bin/env bash
    # generate a WireGuard client configuration
    # usage: wg-mkclient --client-name <name> --client-ip <ip> --tunnel <wg interface>

    set -e

    CLIENT_NAME=""
    CLIENT_IP=""
    TUNNEL=""

    while [[ $# -gt 0 ]]; do
      case $1 in
        --client-name|--name)
          CLIENT_NAME="$2"
          shift
          ;;
        --client-ip|--ip)
          CLIENT_IP="$2"
          shift
          ;;
        --tunnel|--tun)
          TUNNEL="$2"
          shift
          ;;
        *)
          echo "Unknown parameter: $1"
          exit 1
          ;;
      esac
      shift
    done

    if [[ -z $CLIENT_IP ]] || [[ -z $TUNNEL ]] || [[ -z $CLIENT_NAME ]]; then
      echo "Usage: $0 --client-name <name> --client-ip <IP> --tunnel <wg interface>"
      exit 1
    fi

    TEMP_CONF=$(mktemp /tmp/wgclient.conf.XXXXXX)

    CLIENT_PRIV_KEY=$(wg genkey)
    CLIENT_PUB_KEY=$(echo "$CLIENT_PRIV_KEY" | wg pubkey)

    SERVER_PUB_KEY=$(sudo wg show "$TUNNEL" public-key)
    SERVER_IP=$(ip -4 addr show ens3 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | tail -n1)
    SERVER_PORT=$(sudo wg show "$TUNNEL" listen-port)

    cat >"$TEMP_CONF" <<EOF
    [Interface]
    PrivateKey = $CLIENT_PRIV_KEY
    Address = $CLIENT_IP/32
    DNS = ${dnsServer}, ${zone}

    [Peer]
    PublicKey = $SERVER_PUB_KEY
    AllowedIPs = 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
    Endpoint = $SERVER_IP:$SERVER_PORT
    EOF

    cat "$TEMP_CONF"
    printf "\n"
    qrencode -t ansiutf8 <"$TEMP_CONF"

    printf "\nPublic key for keys.nix:\n\n"
    printf "  %s = {\n" "$CLIENT_NAME"
    printf "    wg0 = \"%s\";\n" "$CLIENT_PUB_KEY"
    printf "  };\n"

    printf "\nNixOS peer config for wireguard.nix:\n\n"
    printf "            {\n"
    printf "              PublicKey = wg.publicKeys.%s.wg0;\n" "$CLIENT_NAME"
    printf "              AllowedIPs = [ \"%s/32\" ];\n" "$CLIENT_IP"
    printf "            }\n"

    rm -f "$TEMP_CONF"
  '';
in
{
  imports = [ ./options ];

  environment.systemPackages = with pkgs; [
    conntrack-tools
    wireguard-tools

    iftop
    termshark
    tshark
    qrencode

    flent
    fping
    netperf

    nfw
    wg-mkclient
  ];

  boot.kernel.sysctl."net.ipv4.ip_forward" = "1";
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = "1";

  # prevent networkd from removing routes/rules created by FRR
  systemd.network.config.networkConfig = {
    ManageForeignRoutingPolicyRules = false;
    ManageForeignRoutes = false;
    ManageForeignNextHops = false;
  };
}
