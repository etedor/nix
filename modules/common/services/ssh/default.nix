{
  config,
  globals,
  lib,
  mkModule,
  pkgs,
  specialArgs,
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
    users.users.${user0.name}.openssh.authorizedKeys.keys =
      lib.attrValues keys.users.user0;

    programs.ssh.knownHosts = lib.mapAttrs (name: key: {
      publicKey = key;
      extraHostNames = [ "${name}.${globals.zones.home}" ];
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

    age.secrets.ssh-user0-ed25519 = {
      file = "${specialArgs.secretsCommon}/ssh-user0-ed25519.age";
      owner = user0.name;
      mode = "0400";
      path = "/home/${user0.name}/.ssh/id_ed25519";
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

    # on fresh installs, seed keychain with passphrases:
    #   ssh-add --apple-use-keychain ~/.ssh/id_ed25519
    #   ssh-add --apple-use-keychain ~/.ssh/id_rsa
    age.secrets.ssh-user0-ed25519 = {
      file = "${specialArgs.secretsCommon}/ssh-user0-ed25519.age";
      owner = user0.name;
      group = "staff";
      mode = "0400";
      path = "/Users/${user0.name}/.ssh/id_ed25519";
    };

    age.secrets.ssh-user0-rsa = {
      file = "${specialArgs.secretsCommon}/ssh-user0-rsa.age";
      owner = user0.name;
      group = "staff";
      mode = "0400";
      path = "/Users/${user0.name}/.ssh/id_rsa";
    };

    home-manager.users.${user0.name} = {
      # auto-load keys from keychain after reboot
      programs.ssh.matchBlocks."*" = {
        identityFile = [
          config.age.secrets.ssh-user0-ed25519.path
          config.age.secrets.ssh-user0-rsa.path
        ];
        extraOptions = {
          AddKeysToAgent = "yes";
          UseKeychain = "yes";
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

        beet = {
          description = "beet commands on duke";
          body = ''
            switch $argv[1]
              case import
                set -l zip (basename $argv[2])
                set -l remote /tmp/beet-import
                rsync -avP $argv[2] duke:$remote/ \
                  && rm $argv[2] \
                  && ssh -t duke "beet import '$remote/$zip'"
              case art
                set -l url $argv[2]
                set -l query (printf "'%s' " $argv[3..-1])
                ssh -t duke "beet clearart $query && beet embedart -u '$url' $query && beet extractart -n cover $query"
              case '*'
                ssh -t duke "beet $argv"
            end
          '';
        };
      };
    };
  };
}
