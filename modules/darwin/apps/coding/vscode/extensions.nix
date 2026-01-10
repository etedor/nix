{ pkgs-unstable }:

pkgs-unstable.vscode-utils.extensionsFromVscodeMarketplace [
  {
    name = "prettier-vscode";
    publisher = "esbenp";
    version = "11.0.0";
    sha256 = "pNjkJhof19cuK0PsXJ/Q/Zb2H7eoIkfXJMLZJ4lDn7k=";
  }
  {
    name = "black-formatter";
    publisher = "ms-python";
    version = "2025.3.11831009";
    sha256 = "sha256-FsJHxYHae1NuDXQfOJ4TPnXDy05tTuyCElHD4MiaMDU=";
  }
  {
    name = "shell-format";
    publisher = "foxundermoon";
    version = "7.2.5";
    sha256 = "kfpRByJDcGY3W9+ELBzDOUMl06D/vyPlN//wPgQhByk=";
  }
  {
    name = "theme-monokai-pro-vscode";
    publisher = "monokai";
    version = "1.2.2";
    sha256 = "xeLzzNgj/GmNnSmrwSfJW6i93++HO3MPAj8RwZzwzR4=";
  }

  # go
  {
    name = "go";
    publisher = "golang";
    version = "0.47.1";
    sha256 = "FKbPvXIO7SGt9C2lD7+0Q6yD0QNzrdef1ltsYXPmAi0=";
  }

  # python
  {
    name = "python";
    publisher = "ms-python";
    version = "2025.5.2025042501";
    sha256 = "pCTFGlCrYFdS/zECrdwKOHH0MEHDCM1siBbQ0hI5bqI=";
  }
  # nixos
  {
    name = "direnv";
    publisher = "mkhl";
    version = "0.17.0";
    sha256 = "9sFcfTMeLBGw2ET1snqQ6Uk//D/vcD9AVsZfnUNrWNg=";
  }
  {
    name = "nix";
    publisher = "bbenoist";
    version = "1.0.1";
    sha256 = "qwxqOGublQeVP2qrLF94ndX/Be9oZOn+ZMCFX1yyoH0=";
  }
  {
    name = "nix-ide";
    publisher = "jnoortheen";
    version = "0.4.12";
    sha256 = "3pXypgAwg/iEBUqPeNsyoX2oYqlKMVdemEhmhy1PuGU=";
  }
  # shell
  {
    name = "shellcheck";
    publisher = "timonwong";
    version = "0.37.0";
    sha256 = "jJcKROkZXPwLaCUz7/tDJvShNC/rTJc8+VAwY62nC7Q=";
  }
]
