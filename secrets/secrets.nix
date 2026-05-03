let
  keys = import ../.nix/keys.nix;
  user0 = builtins.attrValues keys.users.user0;
  hosts = keys.hosts;
  common = builtins.attrValues hosts;

  darwin = [
    hosts.carbon
    hosts.garage
    hosts.machina
  ];

  router = [
    hosts.rt-ggz
    hosts.rt-sea
    hosts.rt-sea2
  ];

  server = [
    hosts.duke
  ];
in
{
  "common/mailgun.age".publicKeys = user0 ++ common;
  "common/pushover.age".publicKeys = user0 ++ common;
  "common/smb-user0.age".publicKeys = user0 ++ common;
  "common/ssh-claude-ed25519.age".publicKeys = user0 ++ darwin;
  "common/ssh-claude-rsa.age".publicKeys = user0 ++ darwin;
  "common/ssh-user0-ed25519.age".publicKeys = user0 ++ common;
  "common/ssh-user0-rsa.age".publicKeys = user0 ++ darwin;

  "darwin/atuin-key.age".publicKeys = user0 ++ darwin;
  "darwin/atuin-session.age".publicKeys = user0 ++ darwin;

  "darwin/machina/syncthing-user0-cert.age".publicKeys = user0 ++ [ hosts.machina ];
  "darwin/machina/syncthing-user0-key.age".publicKeys = user0 ++ [ hosts.machina ];
  "darwin/carbon/syncthing-user0-cert.age".publicKeys = user0 ++ [ hosts.carbon ];
  "darwin/carbon/syncthing-user0-key.age".publicKeys = user0 ++ [ hosts.carbon ];
  "darwin/garage/syncthing-user0-cert.age".publicKeys = user0 ++ [ hosts.garage ];
  "darwin/garage/syncthing-user0-key.age".publicKeys = user0 ++ [ hosts.garage ];
  "darwin/garage/syncthing-user1-cert.age".publicKeys = user0 ++ [ hosts.garage ];
  "darwin/garage/syncthing-user1-key.age".publicKeys = user0 ++ [ hosts.garage ];

  "darwin/carbon/wg0-config.age".publicKeys = user0 ++ [ hosts.carbon ];

  "router/atuin-key.age".publicKeys = user0 ++ router;
  "router/atuin-session.age".publicKeys = user0 ++ router;
  "router/knot-tsig-key.age".publicKeys = user0 ++ router;

  "router/rt-ggz/kea-tsig-key.age".publicKeys = user0 ++ [ hosts.rt-ggz ];
  "router/rt-ggz/wg0-private-key.age".publicKeys = user0 ++ [ hosts.rt-ggz ];
  "router/rt-ggz/wg1-private-key.age".publicKeys = user0 ++ [ hosts.rt-ggz ];

  "router/rt-sea/wg0-private-key.age".publicKeys = user0 ++ [ hosts.rt-sea ];
  "router/rt-sea/wg1-private-key.age".publicKeys = user0 ++ [ hosts.rt-sea ];
  "router/rt-sea/wg2-private-key.age".publicKeys = user0 ++ [ hosts.rt-sea ];
  "router/rt-sea/wg10-private-key.age".publicKeys = user0 ++ [ hosts.rt-sea ];
  "router/rt-sea/wg11-private-key.age".publicKeys = user0 ++ [ hosts.rt-sea ];

  "router/rt-sea2/wg0-private-key.age".publicKeys = user0 ++ [ hosts.rt-sea2 ];
  "router/rt-sea2/wg1-private-key.age".publicKeys = user0 ++ [ hosts.rt-sea2 ];
  "router/rt-sea2/wg2-private-key.age".publicKeys = user0 ++ [ hosts.rt-sea2 ];

  "server/atuin-key.age".publicKeys = user0 ++ server;
  "server/atuin-session.age".publicKeys = user0 ++ server;
  "server/nsupdate-tsig-key.age".publicKeys = user0 ++ server;

  "server/duke/syncthing-user0-cert.age".publicKeys = user0 ++ [ hosts.duke ];
  "server/duke/syncthing-user0-key.age".publicKeys = user0 ++ [ hosts.duke ];
  "server/duke/syncthing-user1-cert.age".publicKeys = user0 ++ [ hosts.duke ];
  "server/duke/syncthing-user1-key.age".publicKeys = user0 ++ [ hosts.duke ];

  "server/duke/acme.age".publicKeys = user0 ++ [ hosts.duke ];
  "server/duke/ledger.age".publicKeys = user0 ++ [ hosts.duke ];
  "server/duke/navidrome.age".publicKeys = user0 ++ [ hosts.duke ];
  "server/duke/icecast.age".publicKeys = user0 ++ [ hosts.duke ];
  "server/duke/paperless.age".publicKeys = user0 ++ [ hosts.duke ];
  "server/duke/qobuz.age".publicKeys = user0 ++ [ hosts.duke ];
  "server/duke/quadlink.age".publicKeys = user0 ++ [ hosts.duke ];
  "server/duke/smb-brother.age".publicKeys = user0 ++ [ hosts.duke ];
  "server/duke/restic-pass.age".publicKeys = user0 ++ [ hosts.duke ];
  "server/duke/restic-repo.age".publicKeys = user0 ++ [ hosts.duke ];
}
