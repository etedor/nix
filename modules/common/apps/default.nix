{
  pkgs,
  mkModule,
  ...
}:

mkModule {
  shared = {
    imports = [
      ./git.nix
      ./lnav.nix
      ./vim.nix
    ];

    environment.systemPackages = with pkgs; [
      curl
      duf
      fd
      git
      jless
      jq
      ncdu
      wget
      yq-go

      p7zip
      unzip

      dig
      grepcidr
      inetutils
      ipcalc
      iperf
      mtr
      nmap
      speedtest-cli
      sshs
      whois
    ];
  };

  linux = {
    environment.systemPackages = with pkgs; [
      glances
      iotop

      ethtool
      tcpdump
      traceroute
      tshark
    ];
  };

  darwin = {

  };
}
