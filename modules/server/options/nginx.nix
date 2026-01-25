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
        adminOnly ? true,
        allowIPs ? (if adminOnly then globals.networks.admin else null),
        extraAllowIPs ? [],
        adminPath ? null,
        allowAdminIPs ? null,
        extraConfig ? "",
      }:
      assert (!adminOnly) -> (allowIPs != null) ||
        throw "allowIPs must be specified when adminOnly = false";
      let
        mkAccessControl =
          ips:
          if ips == null || ips == [] then
            ""
          else
            ''
              ${lib.concatMapStrings (ip: "allow ${ip};\n") ips}
              deny all;
            '';

        siteAccessControl = mkAccessControl (allowIPs ++ extraAllowIPs);
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
            error_page 403 = @denied;
            ${extraConfig}
          '';
          forceSSL = true;
          useACMEHost = globals.zone;

          locations = {
            "/" = {
              inherit proxyPass proxyWebsockets;
            };
            "@denied" = {
              return = "444";
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
