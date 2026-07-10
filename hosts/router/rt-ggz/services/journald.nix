{
  # route the chatty, low-forensic-value services to the RAM namespace (defined
  # in modules/common/services/journald.nix) so their logs never hit the NVMe
  systemd.services.blocky.serviceConfig.LogNamespace = "volatile";
  systemd.services.miniupnpd-et42.serviceConfig.LogNamespace = "volatile";
}
