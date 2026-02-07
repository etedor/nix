# mgmt subnet
{
  vlans = {
    lan0 = {
      subnet = "10.1.200.0/24";
      router = "10.1.200.1";
      description = "Management";
      pools = [
        {
          pool = "10.1.200.192 - 10.1.200.254";
          client-classes = [ "lan0" ];
        }
      ];
    };
  };
}
