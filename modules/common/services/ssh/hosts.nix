{ globals }:

user: {
  "docker-home" = {
    HostName = "docker-home.${globals.zones.home}";
    User = user;
  };
  "duke" = {
    HostName = "duke.${globals.zones.home}";
    User = user;
  };
  "ntp" = {
    HostName = "ntp.${globals.zones.home}";
    User = user;
    KexAlgorithms = "+diffie-hellman-group14-sha1";
    HostKeyAlgorithms = "+ssh-rsa";
    PubkeyAcceptedAlgorithms = "+ssh-rsa";
    Ciphers = "+aes256-cbc";
  };
  "rt-ggz" = {
    HostName = "rt-ggz.${globals.zones.home}";
    User = user;
  };
  "rt-sea" = {
    HostName = "rt-sea.${globals.zones.home}";
    User = user;
  };
  "rt-sea2" = {
    HostName = "rt-sea2.${globals.zones.home}";
    User = user;
  };

  "sw-garage" = {
    HostName = "sw-garage.${globals.zones.home}";
    User = user;
    SetEnv.TERM = "xterm-256color";
  };
  "sw-living-room" = {
    HostName = "sw-living-room.${globals.zones.home}";
    User = user;
    KexAlgorithms = "+diffie-hellman-group14-sha1";
    HostKeyAlgorithms = "+ssh-rsa";
    PubkeyAcceptedAlgorithms = "+ssh-rsa";
  };

  "sw-office" = {
    HostName = "sw-office.${globals.zones.home}";
    User = user;
    KexAlgorithms = "+diffie-hellman-group14-sha1";
    HostKeyAlgorithms = "+ssh-rsa";
    PubkeyAcceptedAlgorithms = "+ssh-rsa";
  };
  "sw-playroom" = {
    HostName = "sw-playroom.${globals.zones.home}";
    User = user;
    KexAlgorithms = "+diffie-hellman-group14-sha1";
    HostKeyAlgorithms = "+ssh-rsa";
    PubkeyAcceptedAlgorithms = "+ssh-rsa";
  };

  # https://en.wikiversity.org/wiki/Cisco_IOS/Configure_public_RSA_key_authentication
  # split your key in 72 characters lines: fold -b -w 72 ~/.ssh/id_rsa.pub
  # and copy output removing ssh-rsa and last part: user@host
  "sw-management" = {
    HostName = "192.168.0.1";
    User = user;
    KexAlgorithms = "+diffie-hellman-group14-sha1";
    HostKeyAlgorithms = "+ssh-rsa";
    PubkeyAcceptedAlgorithms = "+ssh-rsa";
  };
  "opengear.ma" = {
    HostName = "192.168.0.16";
    User = user;
  };
  "ntp.ma" = {
    HostName = "192.168.0.17";
    User = user;
    KexAlgorithms = "+diffie-hellman-group14-sha1";
    HostKeyAlgorithms = "+ssh-rsa";
    PubkeyAcceptedAlgorithms = "+ssh-rsa";
    Ciphers = "+aes256-cbc";
  };
  "rt-ggz.ma" = {
    HostName = "192.168.0.32";
    User = user;
  };
  "sw-core.ma" = {
    HostName = "192.168.0.33";
    User = user;
    SetEnv.TERM = "xterm-256color";
  };
  "sw-garage.ma" = {
    HostName = "sw-garage.ma";
    User = user;
    KexAlgorithms = "+diffie-hellman-group14-sha1";
    HostKeyAlgorithms = "+ssh-rsa";
    PubkeyAcceptedAlgorithms = "+ssh-rsa";
  };

  "og-lab-white" = {
    HostName = "172.16.253.24";
    User = user;
  };

  "comcast-ny" = {
    HostName = "route-server.newyork.ny.ibone.comcast.net";
    User = "rviewsxr";
    KexAlgorithms = "+diffie-hellman-group14-sha1";
    HostKeyAlgorithms = "+ssh-rsa";
    PubkeyAcceptedAlgorithms = "+ssh-rsa";
  };
}
