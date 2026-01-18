{ globals, ... }:

let
  user0 = globals.users 0;
  duke = "duke.${globals.zone}";
  mediaOpts = [ "soft" "bg" "intr" "resvport" "nolocks" ];
  usersOpts = [ "soft" "bg" "intr" "resvport" ];
in
{
  et42.device.autofs = {
    enable = true;
    mounts = {
      media = {
        server = duke;
        remotePath = "/pool0/media";
        mountPoint = "/Volumes/duke/media";
        options = mediaOpts;
      };
      users = {
        server = duke;
        remotePath = "/pool0/users/${user0.name}";
        mountPoint = "/Volumes/duke/users/${user0.name}";
        options = usersOpts;
      };
    };
  };
}
