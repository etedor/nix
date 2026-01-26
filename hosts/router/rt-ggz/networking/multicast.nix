{ lib, globals, ... }:

let
  multicastVlans = [
    8
    # 10
  ];

  frrVlanConfig = lib.concatMapStringsSep "\n" (vlan: ''
    interface vlan${toString vlan}
     ip igmp
  '') multicastVlans;

  networkConfigs = lib.listToAttrs (
    map (vlan: {
      name = "40-vlan${toString vlan}";
      value = {
        linkConfig.Multicast = true;
      };
    }) multicastVlans
  );

  brother = globals.hosts.brother;
in
{
  services.frr = {
    pimd.enable = true;
    config = frrVlanConfig;
  };

  # static mDNS services (no reflection)
  services.avahi = {
    enable = true;
    reflector = false;
    allowInterfaces = [ "vlan8" ];
    publish = {
      enable = true;
      addresses = false;
      workstation = false;
    };
    extraServiceFiles = {
      brother-airprint = ''
        <?xml version="1.0" standalone='no'?>
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name>Brother MFC-L2750DW series</name>
          <service>
            <type>_ipp._tcp</type>
            <port>631</port>
            <host-name>brotherdeafea12.local</host-name>
            <txt-record>txtvers=1</txt-record>
            <txt-record>qtotal=1</txt-record>
            <txt-record>pdl=application/octet-stream,image/urf,image/pwg-raster</txt-record>
            <txt-record>rp=ipp/print</txt-record>
            <txt-record>ty=Brother MFC-L2750DW series</txt-record>
            <txt-record>product=(Brother MFC-L2750DW series)</txt-record>
            <txt-record>priority=25</txt-record>
            <txt-record>Color=F</txt-record>
            <txt-record>Copies=T</txt-record>
            <txt-record>Duplex=T</txt-record>
            <txt-record>Fax=T</txt-record>
            <txt-record>Scan=T</txt-record>
            <txt-record>URF=W8,CP1,IS4-1,MT1-3-4-5-8,OB10,PQ3-4-5,RS300-600-1200,V1.4,DM1</txt-record>
            <txt-record>kind=document,envelope,label,postcard</txt-record>
            <txt-record>PaperMax=legal-A4</txt-record>
            <txt-record>UUID=e3248000-80ce-11db-8000-b42200af9e33</txt-record>
            <txt-record>mopria-certified=2.1</txt-record>
          </service>
        </service-group>
      '';
    };
  };

  systemd.network.networks = networkConfigs;
}
