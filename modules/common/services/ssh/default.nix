{
  globals,
  lib,
  mkModule,
  ...
}:

let
  user0 = globals.users 0;
  keys = globals.keys;
in
mkModule {
  shared = {
    users.users.${user0.name}.openssh.authorizedKeys.keys = lib.attrValues keys.users.user0;

    programs.ssh.knownHosts = lib.mapAttrs (name: key: {
      publicKey = key;
      extraHostNames = [ "${name}.${globals.zone}" ];
    }) keys.hosts;

    home-manager.users.${user0.name}.programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = import ./hosts.nix { inherit globals; } user0.name;
    };
  };

  linux = {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
        PermitRootLogin = "no";
      };
    };

    # allow SSH key auth for sudo via forwarded agent
    security.pam.sshAgentAuth = {
      enable = true;
      authorizedKeysFiles = [ "/etc/ssh/authorized_keys.d/%u" ];
    };
    security.pam.services.sudo.sshAgentAuth = true;
    security.sudo.extraConfig = ''
      Defaults env_keep += "SSH_AUTH_SOCK"
    '';
  };

  darwin = {
    services.openssh = {
      enable = true;
    };

    # auto-load keys from keychain after reboot
    home-manager.users.${user0.name}.programs.ssh.matchBlocks."*" = {
      extraOptions = {
        AddKeysToAgent = "yes";
        UseKeychain = "yes";
        IdentityFile = "~/.ssh/id_ed25519";
      };
    };
  };
}
