{
  config,
  globals,
  lib,
  pkgs,
  specialArgs,
  ...
}:

let
  playlists = import ./playlists.nix { inherit config pkgs; };

  setupPlaylistsDir = pkgs.writeShellScript "setup-playlists-dir.sh" ''
    mkdir -p /pool0/media/library/music/_playlists
    rm -f /pool0/media/library/music/_playlists/*.nsp
    cp -f ${playlists.playlistsDir}/* /pool0/media/library/music/_playlists/
    chmod -R 755 /pool0/media/library/music/_playlists
    chown -R 1000:1000 /pool0/media/library/music/_playlists

    # clear playlists table so Navidrome rebuilds from .nsp files
    db_path="/pool0/podman/storage/volumes/navidrome_config/_data/navidrome.db"
    if [ -f "$db_path" ]; then
      ${pkgs.sqlite}/bin/sqlite3 "$db_path" "DELETE FROM playlist;"
    fi
  '';
in
{
  age.secrets.navidrome = {
    file = "${specialArgs.secretsHost}/navidrome.age";
    mode = "400";
    owner = "1000";
    group = "1000";
  };

  systemd.services.podman-navidrome.preStart = "${setupPlaylistsDir}";

  virtualisation.quadlet.containers.navidrome = {
    containerConfig = {
      image = "deluan/navidrome:0.58.0";

      networks = [ "10-default" ];

      environments = {
        PUID = "1000";
        PGID = "1000";
        TZ = globals.tz;
        ND_AUTOIMPORTPLAYLISTS = "true";
        ND_COVERARTPRIORITY = "embedded, cover.png, cover.jpg, cover.*, folder.*";
        ND_ENABLETRANSCODINGCONFIG = "true";
        ND_LOGLEVEL = "debug";
        ND_PLAYLISTSPATH = "_playlists";
        ND_SCANSCHEDULE = "@every 1h";
        ND_SMARTPLAYLISTREFRESHDELAY = "5s";
      };

      environmentFiles = [ config.age.secrets.navidrome.path ];

      volumes = [
        "navidrome_config:/data"
        "/pool0/media/library/music:/music:ro"
      ];

      publishPorts = [
        "4533:4533"
      ];
    };

    serviceConfig = {
      Restart = "always";
    };
  };

  services.nginx.virtualHosts = lib.mkMerge [
    (config.et42.server.nginx.mkVirtualHost {
      subdomain = "navidrome";
      proxyPass = "http://127.0.0.1:4533";
      proxyWebsockets = true;
    })
  ];
}
