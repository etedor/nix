{ mkDomainsFile }:

let
  domains = [
    "streamable.com"
  ];
in
{
  default = [ (mkDomainsFile "allow" domains) ];
}
