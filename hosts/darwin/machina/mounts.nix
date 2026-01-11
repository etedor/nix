{ globals, ... }:

let
  user0 = globals.users 0;
  duke = "duke.${globals.zone}";
in
{
  et42.device.autofs = {
    enable = true;
    mounts = {
      media = {
        server = duke;
        remotePath = "/pool0/media";
        mountPoint = "/Volumes/duke/media";
        options = [ "soft" "bg" "intr" "resvport" "nolocks" ];
      };
      users = {
        server = duke;
        remotePath = "/pool0/users/${user0.name}";
        mountPoint = "/Volumes/duke/users";
        options = [ "soft" "bg" "intr" "resvport" "nolocks" ];
      };
    };
  };
}
