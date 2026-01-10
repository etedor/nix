{
  pkgs,
  ...
}:

{
  boot.kernel.sysctl = {
    # queue / backlog -------------------------------------------------
    # max packets a per-CPU backlog may store before drops.
    "net.core.netdev_max_backlog" = 4096;

    # listen(2) backlog length for local TCP servers.
    "net.core.somaxconn" = 4096;

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
    "net.netfilter.nf_conntrack_tcp_timeout_established" = 7200; # 2h
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
    # from thp split/merge activity at the cost of a small memory-footprint
    # increase.
    "transparent_hugepage=never"

    # lock CPU package and core idle states to C1; prevents deep-C-state
    # exit latency (≈100-200 µs on atom-class silicon) and keeps clocks
    # stable for real-time queues.
    "intel_idle.max_cstate=1"
    "processor.max_cstate=1"

    # instruct the scheduler to spin in a tight loop instead of using
    # the halt instruction when a CPU goes idle--trades watts for the
    # lowest possible wake-up latency.
    "idle=poll"

    # time-stamp counter is trustworthy across frequency changes;
    # prevents timekeeping drift warnings.
    "tsc=reliable"

    # offsets the periodic scheduler tick per CPU so that not all cores
    # receive the timer interrupt at the exact same moment—reduces lock
    # contention on large interrupt fan-outs.
    "skew_tick=1"

    # switch the RCU engine back to normal (low-latency) mode after boot,
    # rather than deferring grace periods; avoids one-off latency spikes
    # measured in milliseconds during network benchmarks.
    "rcu_normal_after_boot=1"

    # disable the NMI watchdog that samples lockups via perf; removes an
    # extra high-priority interrupt source that can pre-empt critical
    # packets.
    "kernel.nmi_watchdog=0"

    # prevent the scheduler from migrating periodic timer events off
    # a busy CPU; keeps timer-driven jitter from contaminating otherwise
    # quiet latency-critical cores.
    "kernel.timer_migration=0"

    # isolate WAN processing cores (CPU6 and CPU7)
    "isolcpus=6,7"
    "nohz_full=6,7"
    "rcu_nocbs=6,7"
  ];

  # use only non-isolated cpus for housekeeping tasks
  systemd.settings.Manager.CPUAffinity = "0 1 2 3 4 5";

  systemd.services.wan-irq-init = {
    description = "set cpu affinity for wan interface irqs";
    after = [
      "network.target"
      "systemd-networkd.service"
    ];
    wants = [
      "network.target"
      "systemd-networkd.service"
    ];
    wantedBy = [ "multi-user.target" ];

    path = with pkgs; [
      bash
      coreutils
      gawk
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "wan-irq-init" ''
        set -euo pipefail

        echo "[wan-irqs] Assigning IRQ affinities for wan0..."

        grep wan0 /proc/interrupts | while read -r irq_line; do
          irq_num=$(echo "$irq_line" | awk '{print $1}' | tr -d :)
          if [[ -n "$irq_num" ]]; then
            # alternate between CPU6 and CPU7 for even/odd IRQ numbers
            if (( irq_num % 2 == 0 )); then
              core=6
            else
              core=7
            fi
            mask=$(printf "%x" $((1 << core)))
            echo "[wan-irqs] IRQ $irq_num → CPU$core (mask $mask)"
            echo "$mask" > /proc/irq/"$irq_num"/smp_affinity
          fi
        done
      '';
    };
  };
  # force all cores into the performance P-state governor; eliminates
  # frequency-scaling latency and guarantees the advertised base clock
  # under bursty traffic.
  powerManagement.cpuFreqGovernor = "performance";
}
