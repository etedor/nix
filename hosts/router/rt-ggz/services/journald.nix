{
  # route miniupnpd to the RAM namespace (defined in
  # modules/common/services/journald.nix) so its flood never hits the NVMe;
  # blocky is routed the same way in the shared router blocky module
  systemd.services.miniupnpd-et42.serviceConfig.LogNamespace = "volatile";
}
