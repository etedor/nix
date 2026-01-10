{
  config,
  specialArgs,
  ...
}:

let
  peers = config.et42.router.peers;
  rt-ggz = peers.rt-ggz;
  rt-sea = peers.rt-sea;
in
{
  age.secrets = {
    wg0-private-key = {
      file = "${specialArgs.secretsHost}/wg0-private-key.age";
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
              Endpoint = "${rt-sea.interfaces.ens3}:51820";
              PublicKey = wg.publicKeys.rt-sea.wg0;
              AllowedIPs = [ "0.0.0.0/0" ];
            }
          ];
        };
      };

      networks = {
        "10-wg0" = {
          matchConfig.Name = "wg0";
          address = [ "${rt-ggz.interfaces.wg0}/31" ];
        };
      };
    };
}
