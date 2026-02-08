# switch SSH provisioning

reference for adding SSH key auth to network switches.

## key generation

### SSH2 pubkey file (ICX)

ICX imports keys via TFTP in RFC4716 (SSH2) format. generate from OpenSSH pubkeys:

```bash
tmpdir=$(mktemp -d) && trap "rm -rf $tmpdir" EXIT
echo "<openssh-pubkey>" > "$tmpdir/key.pub"
ssh-keygen -e -f "$tmpdir/key.pub" | sed "s/^Comment:.*/Comment: <name>/"
```

combine multiple keys into one file, each wrapped in `---- BEGIN/END SSH2 PUBLIC KEY ----`.

### MD5 key-hash (IOS)

IOS registers keys by MD5 fingerprint:

```bash
tmpdir=$(mktemp -d) && trap "rm -rf $tmpdir" EXIT
echo "<openssh-pubkey>" > "$tmpdir/key.pub"
ssh-keygen -l -E md5 -f "$tmpdir/key.pub"
```

output: `4096 MD5:fb:62:0e:92:...` — strip colons and uppercase for IOS config.

## ICX (Brocade/Ruckus)

ref: https://docs.ruckuswireless.com/fastiron/08.0.60/fastiron-08060-securityguide/GUID-DD33D853-DC83-4F74-8157-4C608759933F.html

### import pubkeys

place SSH2 pubkey file on TFTP server (`/srv/tftp/` on rt-ggz, accessible at `10.0.2.2`):

```
scp /tmp/ssh-pub-keys.txt eric@rt-ggz:/srv/tftp/
```

import on switch:

```
device(config)#ip ssh pub-key-file tftp 10.0.2.2 ssh-pub-keys.txt
```

verify:

```
device#show ip client-pub-key
```

### access model

- no SSH exec channel — all commands require `expect`
- disable pager: `skip-page-display`
- privilege is all-or-nothing (no granular read-only like IOS)

## IOS (Cisco)

### register pubkeys

```
ip ssh version 2
ip ssh pubkey-chain
 username <user>
  key-hash ssh-rsa <MD5-FINGERPRINT-NO-COLONS>
```

### AAA (required for SSH exec)

without AAA, SSH exec fails with "Line has invalid autocommand" (CSCdz17608):

```
aaa new-model
aaa authentication login default local
aaa authorization exec default local
```

### read-only access

privilege 5 can run most `show` commands but `show running-config` only displays commands at or below the user's level. use `more system:running-config` instead:

```
username <user> privilege 5 secret 0 <password>
file privilege 5
privilege exec level 5 more
```

access full config: `ssh <user>@<switch> 'more system:running-config'`

### command reference

| command                                 | method                                       |
| --------------------------------------- | -------------------------------------------- |
| `show version`, `show interfaces`, etc. | `ssh user@host 'show version'`               |
| running config                          | `ssh user@host 'more system:running-config'` |

## EOS (Arista)

TODO — standard SSH exec expected to work without workarounds.
