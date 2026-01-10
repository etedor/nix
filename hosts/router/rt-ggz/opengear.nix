{
  globals,
  pkgs,
  ...
}:

let
  user0 = globals.users 0;
in
{
  environment.systemPackages = with pkgs; [
    screen
  ];
  users.users.${user0.name}.extraGroups = [ "dialout" ];

  home-manager.users.${user0.name} = {
    programs.fish.functions = {
      og = ''
        # kill any existing opengear screen sessions
        set -l existing_session (screen -ls | grep "opengear" | awk '{print $1}')
        if test -n "$existing_session"
          screen -X -S $existing_session quit
        end

        set -l device ""
        if test -e "/dev/opengear"
          set device "/dev/opengear"
        else
          # fallback to finding any ttyUSB device
          set -l tty_devices (ls /dev/ttyUSB* 2>/dev/null)
          if test -z "$tty_devices"
            echo "Error: No USB serial devices found"
            return 1
          end
          set device $tty_devices[1]
        end

        echo "startup_message off" > /tmp/opengear-screenrc
        echo "caption always \"OPENGEAR | Escape: ~. | Detach: Ctrl+a,d\"" >> /tmp/opengear-screenrc
        screen -c /tmp/opengear-screenrc -S opengear $device 115200
      '';
    };
  };

  # prolific pl2303 serial adapter
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", SYMLINK+="opengear", GROUP="dialout", MODE="0660"
  '';
}
