# fastmail accounts for macOS, in one configuration profile:
#   - contacts: personal + shared "Global Address Book"  (CardDAV)
#   - calendars and reminders: personal                  (CalDAV)
#   - mail: IMAP + SMTP                                   (imap/smtp.fastmail.com)
#
# all secret data lives in agenix. the encrypted profile holds the app
# password, so the Nix store never sees it. the profile adds every account
# to each Mac (carbon, garage, machina).
#
# ===========================================================================
# ONE-TIME SETUP  (simplified technical english, STE100)
# ===========================================================================
#
# STEP 1 -- MAKE AN APP PASSWORD
#   Open Fastmail in a browser.
#   Go to Settings. Then go to Privacy & Security. Then go to App Passwords.
#   Make a new app password. Give it the name "macos".
#   Give the app password access to Mail, Contacts, and Calendars.
#   One password drives all the accounts in this profile.
#   Copy the 16 letters. You use them in STEP 3.
#
# STEP 2 -- FIND THE MASTER USER NAME  (shared contacts only)
#   The shared address book hides behind a special account name.
#   The name looks like "masteruser_XXXXXXXX@fastmail.com".
#   You must find this name one time.
#   Run this command on any Mac:
#
#       fastmail-carddav-discover eric@tedor.org
#
#   The command asks for the app password. Type it. Then press enter.
#   The command prints the master user name.
#   The command also prints the full server address.
#   Keep both lines. You use the master user name in STEP 3.
#
#   HOW THE COMMAND WORKS:
#   The command sends a PROPFIND request to the Fastmail CardDAV server.
#   The server lists every address book for your account.
#   A shared address book has a name that ends with ".Shared".
#   The command reads the text before ".Shared". That text is the master
#   user name. The master user name does not change, so you find it one time.
#
#   NOTE: only shared contacts need this step. Calendars and mail do not use
#   a master user name. This profile does not add a shared calendar.
#
# STEP 3 -- WRITE THE PROFILE
#   Read the profile text at the bottom of this file.
#   Copy the whole profile text.
#   Change APP_PASSWORD to the app password from STEP 1.
#   Change MASTER to the master user name from STEP 2.
#   Change eric@tedor.org if your Fastmail address is different.
#
# STEP 4 -- ENCRYPT THE PROFILE WITH AGENIX
#   Go to the secrets folder in this repository.
#   Run this command:
#
#       agenix -e darwin/fastmail.age
#
#   An editor opens. Paste the whole profile text. Save the file. Close it.
#   agenix encrypts the profile for user0 and for the three Macs.
#
# STEP 5 -- BUILD EACH MAC
#   Build the system in the normal way. For example:
#
#       sudo darwin-rebuild switch --flake .#machina
#
# STEP 6 -- INSTALL THE PROFILE ON EACH MAC
#   Run this command on the Mac:
#
#       fastmail-profile-install
#
#   macOS shows the profile install screen.
#   Approve the profile in System Settings.
#   The contacts, calendars, reminders, and mail accounts appear.
#
# TO CHANGE THE APP PASSWORD LATER:
#   Make a new app password in Fastmail. Do STEP 4 again with the new value.
#   Build each Mac again. Then run fastmail-profile-install again.
# ===========================================================================

{
  config,
  lib,
  pkgs,
  globals,
  specialArgs,
  ...
}:

let
  user0 = globals.users 0;

  # the encrypted profile is identical on every Mac, so it is a role secret.
  secretFile = "${specialArgs.secretsRole}/fastmail.age";
  hasSecret = builtins.pathExists secretFile;

  # find the hidden master user name for the shared address book.
  # sends a PROPFIND, then prints the name in front of ".Shared".
  discover = pkgs.writeShellScriptBin "fastmail-carddav-discover" ''
    set -eu
    if [ "$#" -lt 1 ]; then
      echo "usage: fastmail-carddav-discover <your-fastmail-address>" >&2
      echo "the command reads the app password from the prompt." >&2
      exit 2
    fi
    addr="$1"

    printf 'app password: ' >&2
    stty -echo 2>/dev/null || true
    IFS= read -r pass
    stty echo 2>/dev/null || true
    printf '\n' >&2

    home="https://carddav.fastmail.com/dav/addressbooks/user/$addr/"
    body='<?xml version="1.0" encoding="utf-8"?><propfind xmlns="DAV:"><prop><displayname/></prop></propfind>'

    resp="$(${pkgs.curl}/bin/curl -fsS -u "$addr:$pass" -X PROPFIND \
      -H 'Depth: 1' -H 'Content-Type: application/xml' \
      --data "$body" "$home")"

    master="$(printf '%s' "$resp" \
      | ${pkgs.gnugrep}/bin/grep -Eo "user/[^<]+\.Shared" \
      | ${pkgs.gnused}/bin/sed -E "s#^user/[^/]+/##; s#\.Shared$##" \
      | head -n1)"

    if [ -z "$master" ]; then
      echo "no shared address book found. check the address and the password." >&2
      exit 1
    fi

    echo "master user name: $master"
    echo "server address:   https://carddav.fastmail.com/dav/addressbooks/user/$addr/$master.Shared/"
  '';

  # copy the decrypted profile to a temp file, then open the install screen.
  installer = pkgs.writeShellScriptBin "fastmail-profile-install" ''
    set -eu
    dir="$(mktemp -d)"
    profile="$dir/fastmail.mobileconfig"
    install -m 600 "${config.age.secrets.fastmail.path}" "$profile"
    echo "opening the profile install screen..."
    open "$profile"
    echo "approve the profile in System Settings > General > Device Management."
    echo "then delete the temp folder: rm -rf $dir"
  '';
in
{
  # the discovery tool needs no secret, so it is always on PATH.
  environment.systemPackages = [ discover ] ++ lib.optional hasSecret installer;

  # wire the encrypted profile only after the secret exists. this keeps
  # `nix flake check` green before the one-time setup above is done.
  age.secrets = lib.optionalAttrs hasSecret {
    fastmail = {
      file = secretFile;
      owner = user0.name;
      group = "staff";
      mode = "0400";
    };
  };
}

# ===========================================================================
# PROFILE TEXT -- paste this in STEP 4.
# change APP_PASSWORD and MASTER. change the address if it is not eric@tedor.org.
# keep the fixed UUIDs, so a re-install updates the accounts in place.
# delete a payload <dict> if you do not want that account.
# ===========================================================================
# <?xml version="1.0" encoding="UTF-8"?>
# <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
# <plist version="1.0">
# <dict>
#   <key>PayloadContent</key>
#   <array>
#
#     <!-- contacts: personal -->
#     <dict>
#       <key>PayloadType</key><string>com.apple.carddav.account</string>
#       <key>PayloadVersion</key><integer>1</integer>
#       <key>PayloadIdentifier</key><string>org.tedor.carddav.personal</string>
#       <key>PayloadUUID</key><string>A1111111-0000-0000-0000-000000000001</string>
#       <key>PayloadDisplayName</key><string>Fastmail Contacts (Personal)</string>
#       <key>CardDAVAccountDescription</key><string>Fastmail - Personal</string>
#       <key>CardDAVHostName</key><string>carddav.fastmail.com</string>
#       <key>CardDAVUsername</key><string>eric@tedor.org</string>
#       <key>CardDAVPassword</key><string>APP_PASSWORD</string>
#       <key>CardDAVUseSSL</key><true/>
#       <key>CardDAVPort</key><integer>443</integer>
#     </dict>
#
#     <!-- contacts: shared "Global Address Book" -->
#     <dict>
#       <key>PayloadType</key><string>com.apple.carddav.account</string>
#       <key>PayloadVersion</key><integer>1</integer>
#       <key>PayloadIdentifier</key><string>org.tedor.carddav.shared</string>
#       <key>PayloadUUID</key><string>A2222222-0000-0000-0000-000000000002</string>
#       <key>PayloadDisplayName</key><string>Fastmail Contacts (Shared)</string>
#       <key>CardDAVAccountDescription</key><string>Fastmail - Global Address Book</string>
#       <key>CardDAVHostName</key><string>carddav.fastmail.com</string>
#       <key>CardDAVUsername</key><string>eric+Shared@tedor.org</string>
#       <key>CardDAVPassword</key><string>APP_PASSWORD</string>
#       <key>CardDAVUseSSL</key><true/>
#       <key>CardDAVPort</key><integer>443</integer>
#       <key>CardDAVPrincipalURL</key><string>https://carddav.fastmail.com/dav/addressbooks/user/eric@tedor.org/MASTER.Shared/</string>
#     </dict>
#
#     <!-- calendars + reminders: personal (auto-discovered) -->
#     <dict>
#       <key>PayloadType</key><string>com.apple.caldav.account</string>
#       <key>PayloadVersion</key><integer>1</integer>
#       <key>PayloadIdentifier</key><string>org.tedor.caldav.personal</string>
#       <key>PayloadUUID</key><string>A4444444-0000-0000-0000-000000000004</string>
#       <key>PayloadDisplayName</key><string>Fastmail Calendars</string>
#       <key>CalDAVAccountDescription</key><string>Fastmail</string>
#       <key>CalDAVHostName</key><string>caldav.fastmail.com</string>
#       <key>CalDAVUsername</key><string>eric@tedor.org</string>
#       <key>CalDAVPassword</key><string>APP_PASSWORD</string>
#       <key>CalDAVUseSSL</key><true/>
#       <key>CalDAVPort</key><integer>443</integer>
#     </dict>
#
#     <!-- mail: IMAP + SMTP -->
#     <dict>
#       <key>PayloadType</key><string>com.apple.mail.managed</string>
#       <key>PayloadVersion</key><integer>1</integer>
#       <key>PayloadIdentifier</key><string>org.tedor.mail.fastmail</string>
#       <key>PayloadUUID</key><string>A3333333-0000-0000-0000-000000000003</string>
#       <key>PayloadDisplayName</key><string>Fastmail Mail</string>
#       <key>EmailAccountDescription</key><string>Fastmail</string>
#       <key>EmailAccountName</key><string>Eric Tedor</string>
#       <key>EmailAccountType</key><string>EmailTypeIMAP</string>
#       <key>EmailAddress</key><string>eric@tedor.org</string>
#       <key>IncomingMailServerHostName</key><string>imap.fastmail.com</string>
#       <key>IncomingMailServerPortNumber</key><integer>993</integer>
#       <key>IncomingMailServerUseSSL</key><true/>
#       <key>IncomingMailServerAuthentication</key><string>EmailAuthPassword</string>
#       <key>IncomingMailServerUsername</key><string>eric@tedor.org</string>
#       <key>IncomingPassword</key><string>APP_PASSWORD</string>
#       <key>OutgoingMailServerHostName</key><string>smtp.fastmail.com</string>
#       <key>OutgoingMailServerPortNumber</key><integer>465</integer>
#       <key>OutgoingMailServerUseSSL</key><true/>
#       <key>OutgoingMailServerAuthentication</key><string>EmailAuthPassword</string>
#       <key>OutgoingMailServerUsername</key><string>eric@tedor.org</string>
#       <key>OutgoingPassword</key><string>APP_PASSWORD</string>
#     </dict>
#
#   </array>
#   <key>PayloadDisplayName</key><string>Fastmail</string>
#   <key>PayloadIdentifier</key><string>org.tedor.fastmail</string>
#   <key>PayloadType</key><string>Configuration</string>
#   <key>PayloadUUID</key><string>A0000000-0000-0000-0000-000000000000</string>
#   <key>PayloadVersion</key><integer>1</integer>
#   <key>PayloadScope</key><string>User</string>
# </dict>
# </plist>
