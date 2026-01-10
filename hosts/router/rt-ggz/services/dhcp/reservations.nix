# DHCP reservations
{
  "10.0.2.0/24" = [
    {
      hostname = "ntp";
      mac = "70:b3:d5:5a:6b:1a";
      ip = "10.0.2.16";
    }
    {
      hostname = "opengear";
      mac = "00:13:c6:05:5b:b7";
      ip = "10.0.2.17";
    }
    {
      hostname = "ap-garage";
      mac = "78:9f:6a:20:38:40";
      ip = "10.0.2.40";
    }
    {
      hostname = "ap-living-room";
      mac = "78:9f:6a:20:53:90";
      ip = "10.0.2.41";
    }
    {
      hostname = "ap-library";
      mac = "78:9f:6a:20:61:a0";
      ip = "10.0.2.42";
    }
    {
      hostname = "ups-garage-20a";
      mac = "00:c0:b7:fe:91:25";
      ip = "10.0.2.48";
    }
    {
      hostname = "ups-office";
      mac = "00:20:85:db:b4:d3";
      ip = "10.0.2.50";
    }
  ];

  "10.0.8.0/22" = [
    {
      hostname = "docker-home";
      mac = "1c:69:7a:00:54:c5";
      ip = "10.0.8.16";
    }
    {
      hostname = "atv-living-room";
      mac = "f0:b3:ec:70:24:35";
      ip = "10.0.9.16";
    }
    {
      hostname = "atv-office";
      mac = "6c:4a:85:3d:23:2f";
      ip = "10.0.9.17";
    }
    {
      hostname = "atv-playroom";
      mac = "f0:b3:ec:7e:27:c4";
      ip = "10.0.9.18";
    }
    {
      hostname = "brother";
      mac = "ac:50:de:af:ea:12";
      ip = "10.0.11.16";
    }
    {
      hostname = "tv-office";
      mac = "80:47:86:e6:08:b3";
      ip = "10.0.11.17";
    }
  ];
}
