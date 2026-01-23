{
  globals,
  lib,
  mkModule,
  pkgs,
  ...
}:

let
  user0 = globals.users 0;
  keys = globals.keys;
  sshHosts = import ./hosts.nix { inherit globals; } user0.name;

  colors =
    let
      goldenAngle = 137.508; # optimal hue distribution for any number of hosts
      sat = 20;
      light = 16;
      fallback = "#2a2b30";

      hostList = lib.naturalSort (builtins.attrNames sshHosts);
      hostHues = lib.imap0 (i: host: {
        inherit host;
        hue = lib.mod (builtins.floor (i * goldenAngle)) 360;
      }) hostList;

      cases = lib.concatMapStringsSep "\n" (h: "${h.host}) hue=${toString h.hue} ;;") hostHues;

      mkColor = color: ''printf '\e]11;%s\a' "${color}"''; # OSC 11: set background
      resetColor = ''printf '\e]111;\a' ''; # OSC 111: reset to default
    in
    {
      inherit fallback;
      set = pkgs.writeShellScript "ssh-color-set" ''
        case "$1" in
        ${cases}
          *) ${mkColor fallback}; exit 0 ;;
        esac
        ${mkColor "$(${pkgs.pastel}/bin/pastel color \"hsl($hue, ${toString sat}%, ${toString light}%)\" | ${pkgs.pastel}/bin/pastel format hex)"}
      '';
      reset = pkgs.writeShellScript "ssh-color-reset" ''
        ${resetColor}
      '';
    };

  sshWrapper = pkgs.writeShellScript "ssh-wrapper" ''
    host="$1"; shift
    trap '${colors.reset}' EXIT
    ${colors.set} "$host"
    /usr/bin/ssh "$@"
  '';
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
      matchBlocks = sshHosts;
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

    home-manager.users.${user0.name} = {
      # auto-load keys from keychain after reboot
      programs.ssh.matchBlocks."*" = {
        extraOptions = {
          AddKeysToAgent = "yes";
          UseKeychain = "yes";
          IdentityFile = "~/.ssh/id_ed25519";
        };
      };

      programs.fish.functions = {
        ssh = {
          wraps = "ssh";
          body = ''
            set -l host (string match -r '[^@]+$' $argv[-1])
            ${sshWrapper} $host $argv
          '';
        };

        sshs = {
          wraps = "sshs";
          body = ''
            command sshs \
              --on-session-start-template '${colors.set} {{{name}}}' \
              --on-session-end-template '${colors.reset}' \
              $argv
            ${colors.reset}
          '';
        };
      };
    };
  };
}
