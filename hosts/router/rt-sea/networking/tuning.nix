{ ... }:

{
  boot.kernel.sysctl = {
    # queue / backlog -------------------------------------------------
    # max packets a per-CPU backlog may store before drops.
    "net.core.netdev_max_backlog" = 4096;

    # listen(2) backlog length for local TCP servers.
    "net.core.somaxconn" = 8192;

    # UDP buffers (bytes) --------------------------------------------
    # default / hard ceiling for rx and tx socket buffers.
    "net.core.rmem_default" = 262144; # 256 KiB
    "net.core.rmem_max" = 4194304; # 4 MiB
    "net.core.wmem_default" = 262144; # 256 KiB
    "net.core.wmem_max" = 4194304; # 4 MiB

    # TCP autotuning windows (min / default / max bytes) -------------
    "net.ipv4.tcp_rmem" = "4096 262144 4194304";
    "net.ipv4.tcp_wmem" = "4096 262144 4194304";

    # time_wait / fin handling ---------------------------------------
    "net.ipv4.tcp_fin_timeout" = 15; # fin_wait-2 lifetime in seconds.

    # syn-flood defence ----------------------------------------------
    "net.ipv4.tcp_max_syn_backlog" = 8192; # pending syn queue
    "net.ipv4.tcp_syncookies" = 1; # enable cookies

    # queuing discipline & congestion control ------------------------
    "net.core.default_qdisc" = "fq_codel"; # fairness + AQM
    "net.ipv4.tcp_congestion_control" = "bbr"; # cc algo

    # path-MTU discovery & TCP hygiene -------------------------------
    "net.ipv4.tcp_mtu_probing" = 1; # probe PMTU black-holes
    "net.ipv4.tcp_sack" = 1; # selective ack
    "net.ipv4.tcp_dsack" = 1; # duplicate sack
    "net.ipv4.tcp_window_scaling" = 1; # >64 KiB windows
    "net.ipv4.tcp_timestamps" = 1; # required for BBR RTT/bandwidth estimation
    "net.ipv4.tcp_tw_reuse" = 0; # don't reuse time_wait sockets

    # conntrack table & time-outs ------------------------------------
    "net.netfilter.nf_conntrack_max" = 262144; # slots
    "net.netfilter.nf_conntrack_tcp_timeout_established" = 300; # 5m
    "net.netfilter.nf_conntrack_udp_timeout" = 30;
    "net.netfilter.nf_conntrack_udp_timeout_stream" = 180;

    # scheduler / busy-poll ------------------------------------------
    "kernel.sched_min_granularity_ns" = "100000"; # 100 µs slice
    "net.core.busy_read" = 50000; # 50 µs poll()
    "net.core.busy_poll" = 50000; # 50 µs SO_BUSY_POLL
    "net.ipv4.tcp_fastopen" = 3; # fast open client+server
  };

  boot.kernelParams = [
    # disable transparent huge pages completely; avoids latency spikes
    # from thp split/merge activity at the cost of a small memory‑footprint
    # increase.
    "transparent_hugepage=never"
  ];
}
