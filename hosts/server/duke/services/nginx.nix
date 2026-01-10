{
  config,
  globals,
  lib,
  ...
}:

let
  z = globals.zone;
in
{
  users.users.nginx.extraGroups = [ "acme" ];
  services.nginx =
    let
      mkVirtualHost = config.et42.server.nginx.mkVirtualHost;

      pduExtraLocations = {
        "/favicon.ico" = {
          proxyPass = "https://www.apc.com/favicon.ico";
          recommendedProxySettings = false;
          extraConfig = ''
            proxy_set_header Referer "";
            proxy_set_header Origin "";
          '';
        };
      };
    in
    {
      enable = true;

      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      appendHttpConfig = ''
        # add dark mode support to default error pages
        # https://github.com/nginx/nginx/pull/567
        sub_filter '<head>' '<head><meta name="color-scheme" content="light dark">';
        sub_filter_once on;

        # websocket upgrade mapping
        map $http_upgrade $connection_upgrade {
          default upgrade;
          "" close;
        }

        # upstream for ruckus unleashed cluster
        upstream unleashed_cluster {
          ip_hash;  # session affinity - same client IP always goes to same AP
          server 10.0.2.40:443 max_fails=3 fail_timeout=30s;
          server 10.0.2.41:443 max_fails=3 fail_timeout=30s;
          server 10.0.2.42:443 max_fails=3 fail_timeout=30s;
        }
      '';

      virtualHosts = lib.mkMerge [
        {
          "_" = {
            locations."/" = {
              return = "404";
            };
          };
        }

        (mkVirtualHost {
          subdomain = "ha";
          proxyPass = "http://docker-home.${z}:8123";
          proxyWebsockets = true;
        })

        (mkVirtualHost {
          subdomain = "nr";
          proxyPass = "http://docker-home.${z}:1880";
          proxyWebsockets = true;
        })

        (mkVirtualHost {
          subdomain = "og";
          proxyPass = "http://opengear.${z}:80";
        })

        (mkVirtualHost {
          subdomain = "wifi";
          proxyPass = "https://unleashed_cluster";
          proxyWebsockets = true;
          extraConfig = ''
            # handle self-signed certificates from unleashed aps
            proxy_ssl_verify off;
          '';
        })

        (mkVirtualHost {
          subdomain = "pdu1";
          proxyPass = "http://10.0.2.51:80";
          extraLocations = pduExtraLocations;
        })

        (mkVirtualHost {
          subdomain = "pdu2";
          proxyPass = "http://10.0.2.52:80";
          extraLocations = pduExtraLocations;
        })

        (mkVirtualHost {
          subdomain = "pdu3";
          proxyPass = "http://10.0.2.53:80";
          extraLocations = pduExtraLocations;
        })

        (mkVirtualHost {
          subdomain = "ups-garage-20a";
          proxyPass = "http://10.0.2.48:80";
        })
        (mkVirtualHost {
          subdomain = "ups-office";
          proxyPass = "http://10.0.2.50:80";
        })

        (mkVirtualHost {
          subdomain = "ai";
          proxyPass = "http://10.0.8.35:3000";
          proxyWebsockets = true;
        })
      ];
    };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
