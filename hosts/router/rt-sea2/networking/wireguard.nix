{
  config,
  globals,
  specialArgs,
  ...
}:

let
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
  };

  systemd.network =
    let
      wg = config.et42.router.wireguard;
    in
    {
      netdevs = {
        # P2P to rt-ggz (dynamic IP — no endpoint, rt-ggz initiates)
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
              PublicKey = wg.publicKeys.rt-ggz.wg1;
              AllowedIPs = [ "0.0.0.0/0" ];
            }
          ];
        };

        # P2P to rt-ggz2 (dynamic IP — no endpoint, rt-ggz2 initiates)
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
              PublicKey = wg.publicKeys.rt-ggz2.wg1;
              AllowedIPs = [ "0.0.0.0/0" ];
            }
          ];
        };

        # P2P to rt-sea
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
              Endpoint = "${rt-sea.interfaces.ens3}:51822";
              PublicKey = wg.publicKeys.rt-sea.wg2;
              AllowedIPs = [ "0.0.0.0/0" ];
            }
          ];
        };
      };

      networks = {
        "10-wg0" = {
          matchConfig.Name = "wg0";
          address = [ "${rt-sea2.interfaces.wg0}/31" ];
        };
        "11-wg1" = {
          matchConfig.Name = "wg1";
          address = [ "${rt-sea2.interfaces.wg1}/31" ];
        };
        "12-wg2" = {
          matchConfig.Name = "wg2";
          address = [ "${rt-sea2.interfaces.wg2}/31" ];
        };
      };
    };
}
