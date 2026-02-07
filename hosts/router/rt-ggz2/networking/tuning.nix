{
  ...
}:

{
  boot.kernel.sysctl = {
    # queue / backlog -------------------------------------------------
    "net.core.netdev_max_backlog" = 4096;
    "net.core.somaxconn" = 4096;

    # UDP buffers (bytes) --------------------------------------------
    "net.core.rmem_default" = 262144; # 256 KiB
    "net.core.rmem_max" = 4194304; # 4 MiB
    "net.core.wmem_default" = 262144; # 256 KiB
    "net.core.wmem_max" = 4194304; # 4 MiB

    # TCP autotuning windows (min / default / max bytes) -------------
    "net.ipv4.tcp_rmem" = "4096 262144 4194304";
    "net.ipv4.tcp_wmem" = "4096 262144 4194304";

    # time_wait / fin handling ---------------------------------------
    "net.ipv4.tcp_fin_timeout" = 15;

    # syn-flood defence ----------------------------------------------
    "net.ipv4.tcp_max_syn_backlog" = 8192;
    "net.ipv4.tcp_syncookies" = 1;

    # queuing discipline & congestion control ------------------------
    "net.core.default_qdisc" = "fq_codel";
    "net.ipv4.tcp_congestion_control" = "bbr";

    # path-MTU discovery & TCP hygiene -------------------------------
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_sack" = 1;
    "net.ipv4.tcp_dsack" = 1;
    "net.ipv4.tcp_window_scaling" = 1;
    "net.ipv4.tcp_timestamps" = 1;
    "net.ipv4.tcp_tw_reuse" = 0;

    # conntrack table & time-outs ------------------------------------
    "net.netfilter.nf_conntrack_max" = 262144;
    "net.netfilter.nf_conntrack_tcp_timeout_established" = 7200; # 2h
    "net.netfilter.nf_conntrack_udp_timeout" = 30;
    "net.netfilter.nf_conntrack_udp_timeout_stream" = 180;

    # scheduler / busy-poll ------------------------------------------
    "kernel.sched_min_granularity_ns" = "100000"; # 100 us slice
    "net.core.busy_read" = 50000; # 50 us poll()
    "net.core.busy_poll" = 50000; # 50 us SO_BUSY_POLL
    "net.ipv4.tcp_fastopen" = 3; # fast open client+server
  };
}
