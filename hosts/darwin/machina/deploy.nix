{ globals, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.deploy-rs ];

  security.pam.services.sudo_local = {
    watchIdAuth = true;
    reattach = true; # required for tmux/SSH sessions
  };

  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "duke.${globals.zone}";
      systems = [ "x86_64-linux" ];
      sshUser = "nixremote";
      sshKey = "/var/root/.ssh/nix-builder";
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUFGNEhxYjZsdWM3Y1UyN0hsT1lNNzN3aVNUdzQ0bHlpazVpdVp2QmxuamcK";
      maxJobs = 4;
      protocol = "ssh-ng";
    }
  ];
  nix.settings.builders-use-substitutes = true;
}
