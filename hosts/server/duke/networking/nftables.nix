{
  lib,
  ...
}:

{
  networking.nftables = {
    enable = true;

    preCheckRuleset = ''
      sed '/bulk\.slice/d' -i ruleset.conf
    '';

    ruleset = ''
      table ip mangle {
        chain output {
          type filter hook output priority mangle; policy accept;

          # mark traffic from bulk slice services
          socket cgroupv2 level 1 "bulk.slice" meta mark set 0x1 counter
        }

        chain forward {
          type filter hook forward priority mangle; policy accept;

          # mark traffic from bulk network containers
          iifname "bulk0" meta mark set 0x1 counter
        }

        chain postrouting {
          type filter hook postrouting priority mangle; policy accept;

          # apply CS1 DSCP to marked non-RFC1918 traffic
          meta mark 0x1 ip daddr != { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } ip dscp set cs1 counter
        }
      }
    '';
  };

  systemd.services.nftables.after = [ "bulk.slice" ];

  networking.firewall.enable = lib.mkDefault true;
}
