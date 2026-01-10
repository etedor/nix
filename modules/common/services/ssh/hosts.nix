{ globals }:

user: {
  "docker-home" = {
    hostname = "docker-home.${globals.zone}";
    user = user;
  };
  "duke" = {
    hostname = "duke.${globals.zone}";
    user = user;
  };
  "ntp" = {
    hostname = "ntp.${globals.zone}";
    user = user;

    extraOptions = {
      KexAlgorithms = "+diffie-hellman-group14-sha1";
      HostKeyAlgorithms = "+ssh-rsa";
      PubkeyAcceptedAlgorithms = "+ssh-rsa";
      Ciphers = "+aes256-cbc";
    };
  };
  "rt-ggz" = {
    hostname = "rt-ggz.${globals.zone}";
    user = user;
  };
  "rt-sea" = {
    hostname = "rt-sea.${globals.zone}";
    user = user;
  };

  "sw-garage" = {
    hostname = "sw-garage.${globals.zone}";
    user = user;
    extraOptions = {
      SetEnv = "TERM=xterm-256color";
    };
  };
  "sw-living-room" = {
    hostname = "sw-living-room.${globals.zone}";
    user = user;

    extraOptions = {
      KexAlgorithms = "+diffie-hellman-group14-sha1";
      HostKeyAlgorithms = "+ssh-rsa";
      PubkeyAcceptedAlgorithms = "+ssh-rsa";
    };
  };

  "sw-office" = {
    hostname = "sw-office.${globals.zone}";
    user = user;

    extraOptions = {
      KexAlgorithms = "+diffie-hellman-group14-sha1";
      HostKeyAlgorithms = "+ssh-rsa";
      PubkeyAcceptedAlgorithms = "+ssh-rsa";
    };
  };
  "sw-playroom" = {
    hostname = "sw-playroom.${globals.zone}";
    user = user;

    extraOptions = {
      KexAlgorithms = "+diffie-hellman-group14-sha1";
      HostKeyAlgorithms = "+ssh-rsa";
      PubkeyAcceptedAlgorithms = "+ssh-rsa";
    };
  };

  # https://en.wikiversity.org/wiki/Cisco_IOS/Configure_public_RSA_key_authentication
  # split your key in 72 characters lines: fold -b -w 72 ~/.ssh/id_rsa.pub
  # and copy output removing ssh-rsa and last part: user@host
  "sw-management" = {
    hostname = "192.168.0.1";
    user = user;

    extraOptions = {
      KexAlgorithms = "+diffie-hellman-group14-sha1";
      HostKeyAlgorithms = "+ssh-rsa";
      PubkeyAcceptedAlgorithms = "+ssh-rsa";
    };
  };
  "opengear.ma" = {
    hostname = "192.168.0.16";
    user = user;
  };
  "ntp.ma" = {
    hostname = "192.168.0.17";
    user = user;

    extraOptions = {
      KexAlgorithms = "+diffie-hellman-group14-sha1";
      HostKeyAlgorithms = "+ssh-rsa";
      PubkeyAcceptedAlgorithms = "+ssh-rsa";
      Ciphers = "+aes256-cbc";
    };
  };
  "rt-ggz.ma" = {
    hostname = "192.168.0.32";
    user = user;
  };
  "sw-core.ma" = {
    hostname = "192.168.0.33";
    user = user;
    extraOptions = {
      SetEnv = "TERM=xterm-256color";
    };
  };
  "sw-garage.ma" = {
    hostname = "sw-garage.ma";
    user = user;

    extraOptions = {
      KexAlgorithms = "+diffie-hellman-group14-sha1";
      HostKeyAlgorithms = "+ssh-rsa";
      PubkeyAcceptedAlgorithms = "+ssh-rsa";
    };
  };

  "og-lab-white" = {
    hostname = "172.16.253.24";
    user = user;
  };

  "comcast-ny" = {
    hostname = "route-server.newyork.ny.ibone.comcast.net";
    user = "rviews";

    extraOptions = {
      KexAlgorithms = "+diffie-hellman-group14-sha1";
      HostKeyAlgorithms = "+ssh-rsa";
      PubkeyAcceptedAlgorithms = "+ssh-rsa";
    };
  };
}
