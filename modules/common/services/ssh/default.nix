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
      settings = sshHosts;
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
      programs.ssh.settings."*" = {
        IdentityFile = [
          config.age.secrets.ssh-user0-ed25519.path
          config.age.secrets.ssh-user0-rsa.path
        ];
        AddKeysToAgent = "yes";
        UseKeychain = "yes";
      };

      xdg.configFile."fish/completions/beet.fish".text = ''
        complete -c beet -n "__fish_seen_subcommand_from import" -F -a "(__beet_import_complete)"
      '';

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

        __beet_import_complete = {
          description = "complete remote paths on duke for beet import";
          body = ''
            set -l token (commandline -ct)
            set -l base /pool0/media/downloads/tidarr
            if test -z "$token"
              command ssh duke "bash -c 'shopt -s nocaseglob; ls -1dp \"\$1\"/*/ 2>/dev/null' -- "(string escape -- $base)
            else if string match -q '/*' -- $token
              command ssh duke "bash -c 'shopt -s nocaseglob; ls -1dp \"\$1\"* 2>/dev/null' -- "(string escape -- "$token")
            else
              command ssh duke "bash -c 'shopt -s nocaseglob; ls -1dp \"\$1\"* 2>/dev/null' -- "(string escape -- "$base/$token")
            end
          '';
        };

        beet = {
          description = "beet commands on duke";
          body = ''
            switch $argv[1]
              case import
                set -l path $argv[-1]
                set -l flags $argv[2..-2]
                if test -e "$path"
                  set -l name (basename $path)
                  set -l remote /tmp/beet-import
                  rsync -avP $path duke:$remote/ \
                    && rm $path \
                    && ssh -t duke "beet import $flags "(string escape -- "$remote/$name")
                else
                  ssh -t duke "beet import $flags "(string escape -- "$path")
                end
              case art
                set -l url (string escape -- $argv[2])
                set -l query (string escape -- $argv[3..-1])
                ssh -t duke "beet clearart $query && beet embedart -u $url $query && beet extractart -n cover $query"
              case '*'
                set -l args (string escape -- $argv)
                ssh -t duke "beet $args"
            end
          '';
        };
      };
    };
  };
}
