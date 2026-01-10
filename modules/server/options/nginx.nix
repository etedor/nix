{
  globals,
  lib,
  ...
}:

{
  options.et42.server.nginx.mkVirtualHost = lib.mkOption {
    type = lib.types.functionTo lib.types.attrs;
    description = "Function to generate an Nginx virtual host with defaults and additional custom locations.";
    default =
      {
        subdomain,
        proxyPass,
        proxyWebsockets ? false,
        faviconPath ? null,
        extraLocations ? { },
        allowIPs ? null,
        adminPath ? null,
        allowAdminIPs ? null,
        extraConfig ? "",
      }:
      let
        mkAccessControl =
          ips:
          if ips == null then
            ""
          else
            ''
              ${lib.concatMapStrings (ip: "allow ${ip};\n") ips}
              deny all;
            '';

        siteAccessControl = mkAccessControl allowIPs;
        adminAccessControl = mkAccessControl allowAdminIPs;

        adminLocation = lib.optionalAttrs (adminPath != null) {
          "${adminPath}" = {
            inherit proxyPass proxyWebsockets;
            extraConfig = adminAccessControl;
          };
        };
      in
      {
        "${subdomain}.${globals.zone}" = {
          extraConfig = ''
            proxy_buffering off;
            ${siteAccessControl}
            ${extraConfig}
          '';
          forceSSL = true;
          useACMEHost = globals.zone;

          locations = {
            "/" = {
              inherit proxyPass proxyWebsockets;
            };
          }
          // lib.optionalAttrs (faviconPath != null) {
            "/favicon.ico" = {
              proxyPass = faviconPath;
            };
          }
          // adminLocation
          // extraLocations;
        };
      };
  };
}
