{
  lib,
  config,
  globals,
  ...
}:

let
  cfg = config.et42.router.dns.blocky;
  knotCfg = config.et42.router.dns.knot;

  allowModule = import ./lists-allow.nix;
  denyModule = import ./lists-deny.nix;

  mkDomainsFile =
    name: domains: builtins.toFile "blocky-${name}.txt" (builtins.concatStringsSep "\n" domains);

  denyLists = denyModule { inherit mkDomainsFile; };
  allowLists = allowModule { inherit mkDomainsFile; };

  # auto-derive conditional mapping for private zones when Knot is co-located
  knotZoneMapping = lib.optionalAttrs knotCfg.enable (
    let
      knotAddr = "${knotCfg.listenAddress}:${toString knotCfg.listenPort}";
    in
    lib.genAttrs knotCfg.reverseZones (_: knotAddr)
    // lib.genAttrs (builtins.attrValues globals.zones) (_: knotAddr)
  );

  # archive.* TLDs — historically poisoned against Cloudflare resolvers
  # (ECS dispute since 2019, fluctuates); Quad9 secondary 149.112.112.112
  # was returning NXDOMAIN as of 2026-05; OpenDNS pinned to wan1 on rt-ggz
  # which is unreliable. AdGuard "unfiltered" anycast pair — same network
  # primary+secondary, DoT to keep transit encrypted, and the unfiltered
  # tier guarantees no category filter touches archive.*.
  archiveTlds = [ "today" "fo" "is" "li" "md" "ph" "vn" ];
  adguardUnfiltered = "tcp-tls:94.140.14.140,tcp-tls:94.140.14.141";
  archiveMapping = builtins.listToAttrs (
    map (tld: { name = "archive.${tld}"; value = adguardUnfiltered; }) archiveTlds
  );
in
{
  options.et42.router.dns.blocky = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable blocky, a fast and lightweight DNS proxy as ad-blocker for local network with many features.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "IP addresses to serve DNS endpoint (TCP and UDP).";
    };

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 53;
      description = "Port to serve DNS endpoint.";
    };

    upstream = lib.mkOption {
      type = lib.types.submodule {
        options = {
          servers = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Upstream DNS servers to use.";
          };

          strategy = lib.mkOption {
            type = lib.types.str;
            default = "parallel_best";
            description = "Determine how and to which upstream DNS servers requests are forwarded.";
          };

          timeout = lib.mkOption {
            type = lib.types.str;
            default = "2s";
            description = "Timeout for the response from the external upstream DNS server.";
          };

          fallback = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "If false (default), return empty result if mapped resolver fails. If true, retry original query with upstream.";
          };
        };
      };
      description = "Blocky upstream DNS configuration.";
    };

    conditionalMapping = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Additional conditional DNS mappings. Private zone mappings are auto-derived when Knot is co-located.";
    };

    denylists = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = {
        default = denyLists.default;
        doh = denyLists.doh;
        local = denyLists.local;
      };
      description = "Denylists to include in blocky configuration.";
    };

    allowlists = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = {
        default = allowLists.default;
      };
      description = "Allowlists to include in blocky configuration.";
    };

    blockType = lib.mkOption {
      type = lib.types.str;
      default = "zeroIP";
      description = ''
        Configure which response should be sent to the client if a requested query is blocked.
        Options:
        - zeroIP: Server returns 0.0.0.0 (or :: for IPv6) as result for A and AAAA queries
        - nxDomain: Return NXDOMAIN as return code
        - custom IPs: Comma separated list of destination IP addresses (e.g., "192.168.1.1, 2001:db8::1")
      '';
    };

    lists = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {
        allow = allowLists;
        deny = denyLists;
      };
      description = "Predefined blocklists for blocky.";
      readOnly = true;
    };

    clientGroupsBlock = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = {
        default = [
          "default"
          "local"
        ];
      };
      description = "Custom client groups for blocking.";
    };

    customDNS = lib.mkOption {
      type = lib.types.submodule {
        options = {
          customTTL = lib.mkOption {
            type = lib.types.str;
            default = "1h";
            description = "TTL used for simple mappings.";
          };

          filterUnmappedTypes = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Filter all queries with unmapped types.";
          };

          rewrite = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            description = "Domain rewrite rules (domain: domain).";
          };

          mapping = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            description = "Custom DNS mappings (hostname: address or CNAME).";
          };

          zone = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "String containing a DNS Zone.";
          };
        };
      };
      default = { };
      description = "Custom DNS configuration for Blocky.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.blocky = {
      enable = true;
      settings = {
        ports.dns = map (addr: "${addr}:${toString cfg.listenPort}") cfg.listenAddress;

        caching.prefetching = true;

        upstreams = {
          strategy = cfg.upstream.strategy;
          timeout = cfg.upstream.timeout;
          groups.default = cfg.upstream.servers;
        };

        conditional = {
          fallbackUpstream = cfg.upstream.fallback;
          mapping = knotZoneMapping // archiveMapping // cfg.conditionalMapping;
        };

        blocking = {
          inherit (cfg) denylists allowlists clientGroupsBlock blockType;
        };

        customDNS =
          lib.mkIf
            (
              cfg.customDNS.mapping != { }
              || cfg.customDNS.rewrite != { }
              || cfg.customDNS.zone != null
            )
            {
              inherit (cfg.customDNS) customTTL filterUnmappedTypes rewrite mapping;
            }
          // lib.optionalAttrs (cfg.customDNS.zone != null) {
            zone = cfg.customDNS.zone;
          };
      };
    };

    networking.firewall = lib.mkIf config.networking.firewall.enable {
      allowedTCPPorts = [ cfg.listenPort ];
      allowedUDPPorts = [ cfg.listenPort ];
    };
  };
}
