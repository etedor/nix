{ lib, config, ... }:

let
  hasForwards = config.et42.router.dns.unbound.forwardAddrs != [ ];
in
{
  options.et42.router.dns.unbound = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable Unbound domain name server.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Interface to use to connect to the network. If none are given the default is to listen to localhost. If an interface name is used instead of an ip address, the list of ip addresses on that interface are used.";
    };

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 5353;
      description = "The port number on which the server responds to queries.";
    };

    forwardAddrs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        A list of upstream DoT servers to forward all queries to when
        specified. Format is "<ip>@<port>#<tls-name>", e.g.
        "1.1.1.1@853#cloudflare-dns.com".
      '';
    };
  };

  config = lib.mkIf config.et42.router.dns.unbound.enable {
    services.unbound = {
      enable = true;

      settings = {
        server = {
          ip-address = lib.mkIf (
            config.et42.router.dns.unbound.listenAddress != null
          ) config.et42.router.dns.unbound.listenAddress;
          port = config.et42.router.dns.unbound.listenPort;

          do-ip6 = false; # TODO: IPv6 support
          access-control = [
            "127.0.0.0/8 allow"
            "10.0.0.0/8 allow"
            "172.16.0.0/12 allow"
            "192.168.0.0/16 allow"
          ];

          edns-buffer-size = 1232;
          harden-dnssec-stripped = true;
          harden-glue = true;
          num-threads = 1;
          prefetch = true;
          so-rcvbuf = "1m";
          use-caps-for-id = false;

          verbosity = 3;

          private-address = [
            "10.0.0.0/8"
            "172.16.0.0/12"
            "192.168.0.0/16"
            "169.254.0.0/16"
            "fd00::/8"
            "fe80::/10"
          ];

          # Mozilla DoH canary domain
          # https://support.mozilla.org/en-US/kb/canary-domain-use-application-dnsnet
          local-zone = [ "use-application-dns.net always_nxdomain" ];
        };

        forward-zone = lib.mkIf hasForwards [
          {
            name = ".";
            forward-first = true; # try DoT before root-hints
            forward-ssl-upstream = true; # use DoT (TCP/853 + TLS)
            forward-addr = config.et42.router.dns.unbound.forwardAddrs;
          }
        ];
      };

    };
  };
}
