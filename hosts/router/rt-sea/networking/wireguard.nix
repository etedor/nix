{
  config,
  globals,
  specialArgs,
  ...
}:

let
  net = globals.networks;
in
{
  age.secrets = {
    wg0-private-key = {
      file = "${specialArgs.secretsHost}/wg0-private-key.age";
      mode = "444";
    };
    wg10-private-key = {
      file = "${specialArgs.secretsHost}/wg10-private-key.age";
      mode = "444";
    };
    wg11-private-key = {
      file = "${specialArgs.secretsHost}/wg11-private-key.age";
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

        "20-wg10" = {
          netdevConfig = {
            Name = "wg10";
            Kind = "wireguard";
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
            {
              # machina
              PublicKey = "NVBeFQ2Ws0UjfY88o+zgiOes5fKUDOqEd/F2IP6iMFY=";
              AllowedIPs = [ "10.100.10.13/32" ];
            }
          ];
        };

        "21-wg11" = {
          netdevConfig = {
            Name = "wg11";
            Kind = "wireguard";
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
          address = [ "10.100.0.0/31" ];
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
