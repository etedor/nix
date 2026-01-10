{
  lib,
  config,
  ...
}:

let
  allowModule = import ./lists-allow.nix;
  denyModule = import ./lists-deny.nix;

  mkDomainsFile =
    name: domains: builtins.toFile "blocky-${name}.txt" (builtins.concatStringsSep "\n" domains);
in
{
  options.et42.router.dns.blocky = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable blocky, a fast and lightweight DNS proxy as ad-blocker for local network with many features.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      description = "Port(s) and optional bind IP address(es) to serve DNS endpoint (TCP and UDP).";
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
      description = "Which DNS resolver(s) should be used for queries for the particular domain (with all subdomains).";
    };

    denylists = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = { };
      description = "Denylists to include in blocky configuration.";
      example = lib.literalExpression ''
        {
          default = config.et42.router.dns.blocky.lists.deny.default;
          doh = config.et42.router.dns.blocky.lists.deny.doh;
          local = config.et42.router.dns.blocky.lists.deny.local;
        }
      '';
    };

    allowlists = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = { };
      description = "Allowlists to include in blocky configuration.";
      example = lib.literalExpression ''
        {
          default = config.et42.router.dns.blocky.lists.allow.default;
        }
      '';
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

    # helper function to format tlds for blocky
    mkTLDs = lib.mkOption {
      type = lib.types.functionTo lib.types.str;
      default = tlds: builtins.concatStringsSep "\n" (map (tld: "/.*\\.${tld}$/") tlds);
      description = "Helper function to format TLDs for blocky.";
      visible = false;
    };

    lists = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {
        allow = allowModule { inherit mkDomainsFile; };
        deny = denyModule { inherit mkDomainsFile; };
      };
      description = "Predefined blocklists for blocky.";
      readOnly = true;
    };

    clientGroupsBlock = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = {
        default = [
          "default"
          "tlds"
        ];
      };
      description = "Custom client groups for blocking.";
      example = lib.literalExpression ''
        {
          default = [ "default" "tlds" ];
          iot = [ "default" "tlds" "doh" ];
        }
      '';
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

  config = lib.mkIf config.et42.router.dns.blocky.enable {
    services.blocky = {
      enable = true;
      settings = {
        ports.dns = config.et42.router.dns.blocky.listenAddress;

        caching.prefetching = true;

        upstreams = {
          strategy = config.et42.router.dns.blocky.upstream.strategy;
          timeout = config.et42.router.dns.blocky.upstream.timeout;
          groups.default = config.et42.router.dns.blocky.upstream.servers;
        };

        conditional = {
          fallbackUpstream = config.et42.router.dns.blocky.upstream.fallback;
          mapping = config.et42.router.dns.blocky.conditionalMapping;
        };

        blocking = {
          denylists = config.et42.router.dns.blocky.denylists;
          allowlists = config.et42.router.dns.blocky.allowlists;
          clientGroupsBlock = config.et42.router.dns.blocky.clientGroupsBlock;
          blockType = config.et42.router.dns.blocky.blockType;
        };

        customDNS =
          lib.mkIf
            (
              config.et42.router.dns.blocky.customDNS.mapping != { }
              || config.et42.router.dns.blocky.customDNS.rewrite != { }
              || config.et42.router.dns.blocky.customDNS.zone != null
            )
            {
              customTTL = config.et42.router.dns.blocky.customDNS.customTTL;
              filterUnmappedTypes = config.et42.router.dns.blocky.customDNS.filterUnmappedTypes;
              rewrite = config.et42.router.dns.blocky.customDNS.rewrite;
              mapping = config.et42.router.dns.blocky.customDNS.mapping;
            }
          // lib.optionalAttrs (config.et42.router.dns.blocky.customDNS.zone != null) {
            zone = config.et42.router.dns.blocky.customDNS.zone;
          };
      };
    };

    networking.firewall = lib.mkIf config.networking.firewall.enable {
      allowedTCPPorts = [
        (builtins.elemAt (lib.splitString ":" config.et42.router.dns.blocky.listenAddress) 1)
      ];

      allowedUDPPorts = [
        (builtins.elemAt (lib.splitString ":" config.et42.router.dns.blocky.listenAddress) 1)
      ];
    };
  };
}
