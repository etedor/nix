{
  config,
  specialArgs,
  ...
}:

{
  age.secrets = {
    wg0-private-key = {
      file = "${specialArgs.secretsHost}/wg0-private-key.age";
      mode = "444";
    };
    wg1-private-key = {
      file = "${specialArgs.secretsHost}/wg1-private-key.age";
      mode = "444";
    };
    wg2-private-key = {
      file = "${specialArgs.secretsHost}/wg2-private-key.age";
      mode = "444";
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

        "11-wg1" = {
          netdevConfig = {
            Name = "wg1";
            Kind = "wireguard";
          };
          wireguardConfig = {
            PrivateKeyFile = config.age.secrets.wg1-private-key.path;
            ListenPort = 51821;
          };
          wireguardPeers = [
            {
              PublicKey = wg.publicKeys.pine.wg0;
              AllowedIPs = [ "10.99.1.11/32" ];
            }
            {
              PublicKey = "NVBeFQ2Ws0UjfY88o+zgiOes5fKUDOqEd/F2IP6iMFY=";
              AllowedIPs = [ "10.99.1.13/32" ];
            }
          ];
        };

        "12-wg2" = {
          netdevConfig = {
            Name = "wg2";
            Kind = "wireguard";
          };
          wireguardConfig = {
            PrivateKeyFile = config.age.secrets.wg2-private-key.path;
            ListenPort = 51822;
          };
          wireguardPeers = [
            {
              PublicKey = wg.publicKeys.jade.wg0;
              AllowedIPs = [ "10.99.2.34/32" ];
            }
          ];
        };
      };

      networks = {
        "10-wg0" = {
          matchConfig.Name = "wg0";
          address = [ "10.99.0.0/31" ];
        };
        "11-wg1" = {
          matchConfig.Name = "wg1";
          address = [ "10.99.1.1/24" ];
        };
        "12-wg2" = {
          matchConfig.Name = "wg2";
          address = [ "10.99.2.1/24" ];
        };
      };
    };
}
