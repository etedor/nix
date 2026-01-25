{
  globals,
  lib,
  ...
}:

let
  rfc1918 = [ "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16" ];
in
{
  options.et42.server.nginx = {
    rfc1918 = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = rfc1918;
      description = "RFC1918 private IP ranges.";
    };
  };

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
        allowIPs ? rfc1918,
        extraAllowIPs ? [],
        adminPath ? null,
        allowAdminIPs ? null,
        extraConfig ? "",
      }:
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
