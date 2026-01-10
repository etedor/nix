#!/usr/bin/env bash
# nfw - nftables firewall log viewer
# usage: nfw [--key=value ...] [--full]
# example: nfw --chain=input --dpt=23 --full

DEFAULT_FIELDS="CHAIN ACTION RULE IN OUT SRC DST PROTO SPT DPT"
FULL=0
declare -A FILTERS

# parse args: --key=value or --full
while [[ $# -gt 0 ]]; do
	case "$1" in
	--full) FULL=1 ;;
	--*=*)
		key="${1#--}"
		FILTERS[${key%%=*}]="${key#*=}"
		;;
	--*)
		# handle --key value format
		key="${1#--}"
		if [[ -n $2 && ! $2 =~ ^-- ]]; then
			FILTERS[$key]="$2"
			shift
		fi
		;;
	esac
	shift
done

# build awk filter string
AWK_FILTERS=""
for k in "${!FILTERS[@]}"; do
	AWK_FILTERS+="${k^^}=${FILTERS[$k]};"
done

journalctl -k -f --since "now" -o cat --grep="nftables" | awk -v filters="$AWK_FILTERS" -v full="$FULL" -v fields="$DEFAULT_FIELDS" '
BEGIN {
  # parse filter string into array
  n = split(filters, f, ";")
  for (i = 1; i <= n; i++) {
    if (f[i] ~ /=/) {
      idx = index(f[i], "=")
      key = substr(f[i], 1, idx - 1)
      val = substr(f[i], idx + 1)
      filter[key] = tolower(val)
    }
  }
  # parse default fields into array
  nfields = split(fields, show_fields, " ")
}

function hash_color(s,    h, i, c) {
  # deterministic color from string (ansi 31-36)
  h = 0
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    h = (h * 37 + i * 7 + index(" 0123456789abcdefghijklmnopqrstuvwxyz", tolower(c))) % 1000000
  }
  return 31 + (h % 6)
}

function colorize(key, val) {
  return key "=\033[" hash_color(val) "m" val "\033[0m"
}

function glob_match(str, pattern,    regex) {
  # convert glob pattern to regex
  regex = pattern
  gsub(/\./, "\\.", regex)
  gsub(/\*/, ".*", regex)
  gsub(/\?/, ".", regex)
  return tolower(str) ~ "^" regex "$"
}

/nftables:/ {
  # parse key=value pairs
  delete kv
  for (i = 1; i <= NF; i++) {
    if ($i ~ /=/) {
      idx = index($i, "=")
      key = toupper(substr($i, 1, idx - 1))
      val = substr($i, idx + 1)
      kv[key] = val
    }
  }

  # split MAC into SMAC/DMAC (format: dmac:dmac:dmac:dmac:dmac:dmac:smac:smac:smac:smac:smac:smac:ethertype)
  if ("MAC" in kv) {
    mac = kv["MAC"]
    # first 17 chars = DMAC (aa:bb:cc:dd:ee:ff)
    # chars 19-35 = SMAC
    if (length(mac) >= 35) {
      kv["DMAC"] = substr(mac, 1, 17)
      kv["SMAC"] = substr(mac, 19, 17)
    }
  }

  # apply filters (case-insensitive glob match)
  skip = 0
  for (fkey in filter) {
    if (fkey in kv) {
      if (!glob_match(kv[fkey], filter[fkey])) {
        skip = 1
        break
      }
    } else {
      # filter key not in log entry - skip unless its SMAC/DMAC which we synthesized
      if (fkey != "SMAC" && fkey != "DMAC") {
        skip = 1
        break
      }
    }
  }
  if (skip) next

  # output
  out = ""
  if (full) {
    # show SMAC/DMAC first, then other fields
    if ("SMAC" in kv) out = out " " colorize("SMAC", kv["SMAC"])
    if ("DMAC" in kv) out = out " " colorize("DMAC", kv["DMAC"])
    for (key in kv) {
      if (key != "MAC" && key != "SMAC" && key != "DMAC") {
        out = out " " colorize(key, kv[key])
      }
    }
  } else {
    # show SMAC/DMAC if in default fields, then other default fields
    if ("SMAC" in kv) out = out " " colorize("SMAC", kv["SMAC"])
    if ("DMAC" in kv) out = out " " colorize("DMAC", kv["DMAC"])
    for (i = 1; i <= nfields; i++) {
      key = show_fields[i]
      if (key in kv) {
        out = out " " colorize(key, kv[key])
      }
    }
  }
  if (out != "") print substr(out, 2)  # trim leading space
}
'
