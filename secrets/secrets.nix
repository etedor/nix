let
  keys = import ../.nix/keys.nix;
  user0 = builtins.attrValues keys.users.user0;
  hosts = keys.hosts;
  common = builtins.attrValues hosts;
in
{
  "common/mailgun.age".publicKeys = user0 ++ common;
  "common/pushover.age".publicKeys = user0 ++ common;
  "common/smb-user0.age".publicKeys = user0 ++ common;

  "router/rt-ggz/kea-tsig-key.age".publicKeys = user0 ++ [ hosts.rt-ggz ];
  "router/rt-ggz/knot-tsig-key.age".publicKeys = user0 ++ [ hosts.rt-ggz ];
  "router/rt-ggz/nsd-tsig-key.age".publicKeys = user0 ++ [ hosts.rt-ggz ];
  "router/rt-ggz/wg0-private-key.age".publicKeys = user0 ++ [ hosts.rt-ggz ];

  "router/rt-sea/wg0-private-key.age".publicKeys = user0 ++ [ hosts.rt-sea ];
  "router/rt-sea/wg1-private-key.age".publicKeys = user0 ++ [ hosts.rt-sea ];
  "router/rt-sea/wg2-private-key.age".publicKeys = user0 ++ [ hosts.rt-sea ];

  "server/duke/acme.age".publicKeys = user0 ++ [ hosts.duke ];
  "server/duke/navidrome.age".publicKeys = user0 ++ [ hosts.duke ];
  "server/duke/icecast.age".publicKeys = user0 ++ [ hosts.duke ];
  "server/duke/paperless.age".publicKeys = user0 ++ [ hosts.duke ];
  "server/duke/qobuz.age".publicKeys = user0 ++ [ hosts.duke ];
  "server/duke/smb-brother.age".publicKeys = user0 ++ [ hosts.duke ];
  "server/duke/restic-pass.age".publicKeys = user0 ++ [ hosts.duke ];
  "server/duke/restic-repo.age".publicKeys = user0 ++ [ hosts.duke ];
}
