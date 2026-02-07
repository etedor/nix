{
  config,
  globals,
  specialArgs,
  ...
}:

let
  net = globals.networks;
  rt-sea = globals.routers.rt-sea;
  rt-sea2 = globals.routers.rt-sea2;
in
{
  age.secrets = {
    wg0-private-key = {
      file = "${specialArgs.secretsHost}/wg0-private-key.age";
      mode = "0440";
      group = "systemd-network";
    };
    wg1-private-key = {
      file = "${specialArgs.secretsHost}/wg1-private-key.age";
      mode = "0440";
      group = "systemd-network";
    };
    wg2-private-key = {
      file = "${specialArgs.secretsHost}/wg2-private-key.age";
      mode = "0440";
      group = "systemd-network";
    };
    wg10-private-key = {
      file = "${specialArgs.secretsHost}/wg10-private-key.age";
      mode = "0440";
      group = "systemd-network";
    };
    wg11-private-key = {
      file = "${specialArgs.secretsHost}/wg11-private-key.age";
      mode = "0440";
      group = "systemd-network";
    };
  };

  systemd.network =
    let
      wg = config.et42.router.wireguard;
    in
    {
      netdevs = {
        "10-wg0" = {
          netdevConfig = {
            Name = "wg0";
            Kind = "wireguard";
            MTUBytes = "1420";
          };
          wireguardConfig = {
            PrivateKeyFile = config.age.secrets.wg0-private-key.path;
            ListenPort = 51820;
          };
          wireguardPeers = [
            {
              PublicKey = wg.publicKeys.rt-ggz.wg0;
              AllowedIPs = [ "0.0.0.0/0" ];
            }
          ];
        };

        # P2P to rt-ggz2 (dynamic IP, no endpoint — rt-ggz2 initiates)
        "11-wg1" = {
          netdevConfig = {
            Name = "wg1";
            Kind = "wireguard";
            MTUBytes = "1420";
          };
          wireguardConfig = {
            PrivateKeyFile = config.age.secrets.wg1-private-key.path;
            ListenPort = 51821;
          };
          wireguardPeers = [
            {
              PublicKey = wg.publicKeys.rt-ggz2.wg0;
              AllowedIPs = [ "0.0.0.0/0" ];
            }
          ];
        };

        # P2P to rt-sea2
        "12-wg2" = {
          netdevConfig = {
            Name = "wg2";
            Kind = "wireguard";
            MTUBytes = "1420";
          };
          wireguardConfig = {
            PrivateKeyFile = config.age.secrets.wg2-private-key.path;
            ListenPort = 51822;
          };
          wireguardPeers = [
            {
              Endpoint = "${rt-sea2.interfaces.wan0}:51822";
              PublicKey = wg.publicKeys.rt-sea2.wg2;
              AllowedIPs = [ "0.0.0.0/0" ];
            }
          ];
        };

        "20-wg10" = {
          netdevConfig = {
            Name = "wg10";
            Kind = "wireguard";
            MTUBytes = "1420";
          };
          wireguardConfig = {
            PrivateKeyFile = config.age.secrets.wg10-private-key.path;
            ListenPort = 51830;
          };
          wireguardPeers = [
            {
              PublicKey = wg.publicKeys.pine.wg0;
              AllowedIPs = [ "10.100.10.11/32" ];
            }
            {
              PublicKey = wg.publicKeys.carbon.wg0;
              AllowedIPs = [ "10.100.10.12/32" ];
            }
          ];
        };

        "21-wg11" = {
          netdevConfig = {
            Name = "wg11";
            Kind = "wireguard";
            MTUBytes = "1420";
          };
          wireguardConfig = {
            PrivateKeyFile = config.age.secrets.wg11-private-key.path;
            ListenPort = 51831;
          };
          wireguardPeers = [
            {
              PublicKey = wg.publicKeys.rt-travel.wg0;
              AllowedIPs = [
                "10.100.11.11/32"
                net.travel.lan
              ];
            }
            {
              PublicKey = wg.publicKeys.jade.wg0;
              AllowedIPs = [ "10.100.11.34/32" ];
            }
          ];
        };
      };

      networks = {
        "10-wg0" = {
          matchConfig.Name = "wg0";
          address = [ "${rt-sea.interfaces.wg0}/31" ];
        };
        "11-wg1" = {
          matchConfig.Name = "wg1";
          address = [ "${rt-sea.interfaces.wg1}/31" ];
        };
        "12-wg2" = {
          matchConfig.Name = "wg2";
          address = [ "${rt-sea.interfaces.wg2}/31" ];
        };
        "20-wg10" = {
          matchConfig.Name = "wg10";
          address = [ "10.100.10.1/24" ];
        };
        "21-wg11" = {
          matchConfig.Name = "wg11";
          address = [ "10.100.11.1/24" ];
        };
      };
    };
}
