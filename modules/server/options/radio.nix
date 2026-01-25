{
  config,
  globals,
  lib,
  pkgs,
  ...
}:

let
  liquidsoap_user = config.services.liquidsoap.user or "liquidsoap";
  liquidsoap_group = config.services.liquidsoap.group or "liquidsoap";

  icecast_user = config.services.icecast.user or "icecast";
  icecast_group = config.services.icecast.group or "icecast";

  mkLiquidsoapTemplate =
    station:
    let
      name = station.name;
      url = station.url;
      fullName = station.fullName or name;
      description = station.description or "";
      genre = station.genre or "";
      port = toString (station.port or config.et42.server.radio.port);

      nameField = lib.optionalString (fullName != "") ''name="${fullName}",'';
      descField = lib.optionalString (description != "") ''description="${description}",'';
      genreField = lib.optionalString (genre != "") ''genre="${genre}",'';
    in
    ''
      settings.log.level := 4
      settings.http.mime.extnames := [
        ("audio/x-mpegurl", ".m3u"),
        ("audio/aacp", ".aac")
      ]

      source = input.http("${url}")
      radio = fallback(track_sensitive=false, [stereo(source), blank(duration=1.0)])

      output.icecast(
        %fdkaac,
        host = "127.0.0.1",
        port = ${port},
        password = "#{source_password}",
        mount = "/${name}.aac",
        send_icy_metadata=true,
        ${nameField}
        ${descField}
        ${genreField}
        on_error = fun(err) -> begin
          print("Icecast error: #{err}")
          5.0 # retry
        end,
        radio)
    '';

  # helper to generate icecast mount configuration
  mkIcecastMount =
    station:
    let
      name = station.name;
    in
    ''
      <mount>
        <mount-name>/${name}.aac</mount-name>
        <format>AAC</format>
      </mount>
    '';

  icecastConfig = pkgs.writeText "icecast-template.xml" ''
    <icecast>
      <hostname>${config.networking.hostName}</hostname>
      <location>${config.et42.server.radio.location}</location>
      <admin>${config.et42.server.radio.adminContact}</admin>
      <authentication>
        <admin-user>admin</admin-user>
        <admin-password>#{admin_password}</admin-password>
        <source-password>#{source_password}</source-password>
        <relay-password>#{source_password}</relay-password>
      </authentication>
      <paths>
        <logdir>${config.services.icecast.logDir}</logdir>
        <adminroot>${pkgs.icecast}/share/icecast/admin</adminroot>
        <webroot>${pkgs.icecast}/share/icecast/web</webroot>
        <alias source="/" dest="/status.xsl"/>
        <mime-types>${pkgs.mailcap}/etc/mime.types</mime-types>
      </paths>
      <listen-socket>
        <port>${toString config.et42.server.radio.port}</port>
        <bind-address>${config.services.icecast.listen.address or "127.0.0.1"}</bind-address>
      </listen-socket>
      <security>
        <chroot>0</chroot>
        <changeowner>
          <user>${icecast_user}</user>
          <group>${icecast_group}</group>
        </changeowner>
      </security>

      <!-- mount point configurations -->
      ${lib.concatMapStrings mkIcecastMount config.et42.server.radio.stations}
    </icecast>
  '';

  # station config derivation - rebuilds when config changes
  mkStationScript =
    station: pkgs.writeText "liquidsoap-${station.name}.liq" (mkLiquidsoapTemplate station);

  # map of station names to their script derivations
  stationScripts = lib.listToAttrs (
    map (station: {
      name = station.name;
      value = mkStationScript station;
    }) config.et42.server.radio.stations
  );
in
{
  options.et42.server.radio = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable radio streaming system with Liquidsoap and Icecast";
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 8000;
      description = "Port for Icecast server";
    };

    credentialsFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the file containing admin_password and source_password credentials";
      example = "config.age.secrets.icecast.path";
    };

    location = lib.mkOption {
      type = lib.types.str;
      default = "Earth";
      description = "Geographic location of the Icecast server";
    };

    adminContact = lib.mkOption {
      type = lib.types.str;
      default = "icemaster@localhost";
      description = "Admin contact email for the Icecast server";
      example = "admin@example.com";
    };

    adminIPs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of IP addresses allowed to access admin interface";
    };

    stations = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = ''
        List of radio stations to configure.
        Each entry should have:
        {
          name = "station-slug"; # required, short name used in URLs
          url = "https://...";   # required, source stream URL
          fullName = "Station Name"; # optional, human-readable name
          description = "Description"; # optional
          genre = "Genre"; # optional
        }
      '';
    };
  };

  config = lib.mkIf config.et42.server.radio.enable {
    systemd.tmpfiles.rules = [
      "d /run/radio 0755 root root -"
      "d /run/radio/liquidsoap 0750 ${liquidsoap_user} ${liquidsoap_group} -"
      "d /run/radio/icecast 0750 ${icecast_user} ${icecast_group} -"
    ];

    systemd.services = lib.mkMerge [
      {
        radio-init = {
          description = "Radio Configuration Generator";
          wantedBy = [ "multi-user.target" ];
          after = [ "systemd-tmpfiles-setup.service" ];
          before = [
            "icecast.service"
          ]
          ++ (map (s: "liquidsoap-${s.name}.service") config.et42.server.radio.stations);

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = "root";
            Group = "root";
          };

          script = ''
            mkdir -p /run/radio/liquidsoap
            mkdir -p /run/radio/icecast

            chown ${icecast_user}:${icecast_group} /run/radio/icecast
            chmod 750 /run/radio/icecast
            chown ${liquidsoap_user}:${liquidsoap_group} /run/radio/liquidsoap
            chmod 750 /run/radio/liquidsoap

            # extract passwords from credentials file
            admin_password=$(grep "admin_password" ${config.et42.server.radio.credentialsFile} | cut -d= -f2)
            source_password=$(grep "source_password" ${config.et42.server.radio.credentialsFile} | cut -d= -f2)

            # generate icecast config with secrets substitution
            cp ${icecastConfig} /run/radio/icecast/icecast.xml
            sed -i "s/#{admin_password}/$admin_password/g" /run/radio/icecast/icecast.xml
            sed -i "s/#{source_password}/$source_password/g" /run/radio/icecast/icecast.xml
            chown ${icecast_user}:${icecast_group} /run/radio/icecast/icecast.xml
            chmod 640 /run/radio/icecast/icecast.xml

            # icecast expects mime.types at /etc/mime.types
            if [ ! -e /etc/mime.types ]; then
              ln -sf ${pkgs.mailcap}/etc/mime.types /etc/mime.types
            fi

            # generate liquidsoap configs (cp establishes nix store dependency)
            ${lib.concatMapStrings (station: ''
              cp ${stationScripts.${station.name}} /run/radio/liquidsoap/${station.name}.liq
              sed -i "s/#{source_password}/$source_password/g" /run/radio/liquidsoap/${station.name}.liq
              chown ${liquidsoap_user}:${liquidsoap_group} /run/radio/liquidsoap/${station.name}.liq
              chmod 640 /run/radio/liquidsoap/${station.name}.liq
            '') config.et42.server.radio.stations}
          '';
        };

        icecast = {
          serviceConfig.ExecStart = lib.mkForce "${pkgs.icecast}/bin/icecast -c /run/radio/icecast/icecast.xml";
        };
      }

      # create liquidsoap service overrides with restart triggers
      (lib.listToAttrs (
        map (station: {
          name = "liquidsoap-${station.name}";
          value = {
            wants = [ "network-online.target" ];
            after = [ "network-online.target" ];

            restartTriggers = [
              stationScripts.${station.name}
            ];
          };
        }) config.et42.server.radio.stations
      ))
    ];

    environment.systemPackages = [ pkgs.mailcap ];

    services.icecast = {
      enable = true;
      admin.password = "dummy";
      hostname = config.networking.hostName;
      listen.port = config.et42.server.radio.port;
    };

    services.liquidsoap.streams = lib.listToAttrs (
      map (station: {
        name = "liquidsoap-${station.name}";
        value = "/run/radio/liquidsoap/${station.name}.liq";
      }) config.et42.server.radio.stations
    );

    services.nginx.virtualHosts = lib.mkMerge [
      (config.et42.server.nginx.mkVirtualHost {
        subdomain = "radio";
        proxyPass = "http://127.0.0.1:${toString config.et42.server.radio.port}";
        adminOnly = false;
        allowIPs = globals.networks.admin ++ globals.networks.family;
        adminPath = "/admin/";
        allowAdminIPs = config.et42.server.radio.adminIPs;
      })
    ];

  };
}
