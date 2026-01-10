{ mkDomainsFile }:

let
  github = "https://raw.githubusercontent.com";

  hagezi = x: "${github}/hagezi/dns-blocklists/main/wildcard/${x}.txt";
  nextdns = x: "${github}/nextdns/native-tracking-domains/main/domains/${x}";
  oisd = x: "https://${x}.oisd.nl/domainswild";

  mkTLDs = tlds: map (tld: "/.*\\.${tld}$/") tlds;

  domains = [
  ];

  tlds = [
    "cn"
    "ir"
    "kp"
    "ru"
    "zip"
  ];

  local = mkDomainsFile "deny" (domains ++ mkTLDs tlds);
in
{
  default = [
    (hagezi "tif")

    (nextdns "apple")
    (nextdns "samsung")
    (nextdns "sonos")
    (nextdns "windows")

    (oisd "big")
    (oisd "nsfw")
  ];
  doh = [ (hagezi "doh") ];
  local = [ local ];
}
