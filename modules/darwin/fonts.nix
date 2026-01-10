{
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

{
  fonts.packages = [
    pkgs.font-awesome
  ]
  ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs-unstable.nerd-fonts);
}
