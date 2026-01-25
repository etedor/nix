{
  config,
  lib,
  ...
}:

let
  # string helpers
  concatStringsSep = builtins.concatStringsSep;
  optionalString = lib.optionalString;

  # join list of strings by newline
  join = rules: concatStringsSep "\n" rules;

  # sanitize rule names (spaces → hyphens)
  sanitize = s: builtins.replaceStrings [ " " ] [ "-" ] s;

  mkLog =
    {
      name,
      action,
      logLimit ? "rate 300/minute burst 200 packets",
      logPrefix ? null,
    }:
    let
      safeName = sanitize name;
      prefix = if logPrefix != null then logPrefix else "nftables: RULE=${safeName} ACTION=${action} ";
    in
    "limit ${logLimit} log prefix \"${prefix}\" comment \"${name} log\"";

  # check if all items in list are negated (start with !)
  isNegated = s: builtins.isString s && builtins.substring 0 1 s == "!";
  stripNeg = s: builtins.substring 1 (builtins.stringLength s - 1) s;
  allNegated = items: builtins.isList items && builtins.all isNegated items;

  # build nft match set from list
  mkSet =
    item:
    if builtins.isList item then
      # normal set: { x, y, z }
      "{ ${concatStringsSep ", " (builtins.map builtins.toString item)} }"
    else
      throw "mkSet only accepts a list, not ${builtins.typeOf item}!";

  # build field match, handling negated sets: field != x field != y field != z
  mkFieldMatch =
    field: items:
    if allNegated items then
      concatStringsSep " " (builtins.map (s: "${field} != ${stripNeg s}") items)
    else
      "${field} ${mkSet items}";

  mkRule =
    attrs:
    let
      name = if attrs ? name then attrs.name else throw "mkRule: name is required";
      safeName = sanitize name;
      action = if attrs ? action then attrs.action else throw "mkRule: action is required";
      _ = lib.assertMsg (
        !((attrs ? dpts || attrs ? spts) && !(attrs ? proto))
      ) "mkRule: ${name}: When specifying dpts or spts, you must also specify proto";

      proto = attrs.proto or null;
      protoIsList = builtins.isList proto;
      protoMatch = if protoIsList then mkSet proto else proto;
      baseMatch =
        let
          # build auto-generated match from sips/dips/iifs/oifs/ports/proto
          autoMatch =
            let
              toMatch = [
                (optionalString (attrs ? iifs) "iifname ${mkSet attrs.iifs}")
                (optionalString (attrs ? oifs) "oifname ${mkSet attrs.oifs}")
                (optionalString (attrs ? sips) (mkFieldMatch "ip saddr" attrs.sips))
                (optionalString (attrs ? dips) (mkFieldMatch "ip daddr" attrs.dips))
              ]
              ++ (
                if attrs ? proto then
                  if protoIsList then
                    # multiple protocols - use meta l4proto with th (transport header) for ports
                    if attrs ? spts && attrs ? dpts then
                      [ "meta l4proto ${protoMatch} th sport ${mkSet attrs.spts} th dport ${mkSet attrs.dpts}" ]
                    else if attrs ? spts then
                      [ "meta l4proto ${protoMatch} th sport ${mkSet attrs.spts}" ]
                    else if attrs ? dpts then
                      [ "meta l4proto ${protoMatch} th dport ${mkSet attrs.dpts}" ]
                    else
                      [ "meta l4proto ${protoMatch}" ]
                  else
                  # single protocol - use protocol-specific port matching
                  if attrs ? spts && attrs ? dpts then
                    [ "${proto} sport ${mkSet attrs.spts} ${proto} dport ${mkSet attrs.dpts}" ]
                  else if attrs ? spts then
                    [ "${proto} sport ${mkSet attrs.spts}" ]
                  else if attrs ? dpts then
                    [ "${proto} dport ${mkSet attrs.dpts}" ]
                  else
                    [ "meta l4proto ${proto}" ]
                else
                  [ ]
              );
            in
            concatStringsSep " " (builtins.filter (s: s != "") toMatch);

          # custom expression (if provided)
          customExpr = attrs.expr or "";

          # combine auto-generated and custom expressions
          parts = builtins.filter (s: s != "") [
            autoMatch
            customExpr
          ];
        in
        concatStringsSep " " parts;
      log = attrs.log or false;
      logLimit = attrs.logLimit or "rate 300/minute burst 200 packets";
      logPrefix = attrs.logPrefix or "nftables: RULE=${safeName} ACTION=${action} ";

      # generate the log line separately
      logLine = mkLog {
        name = name;
        action = action;
        logLimit = logLimit;
        logPrefix = logPrefix;
      };

      rule =
        if log then
          "${baseMatch} ${logLine}\n${baseMatch} ${action} comment \"${name}\""
        else
          "${baseMatch} ${action} comment \"${name}\"";
    in
    rule;

  mkDnatRule =
    attrs:
    let
      name = if attrs ? name then attrs.name else throw "mkDnatRule: name required";
      safeName = sanitize name;
      iifs = if attrs ? iifs then attrs.iifs else throw "mkDnatRule: iifs required";
      ip = if attrs ? ip then attrs.ip else throw "mkDnatRule: ip required";
      pt = if attrs ? pt then attrs.pt else throw "mkDnatRule: pt required";
      proto = attrs.proto or "tcp";
      sips = attrs.sips or [ ]; # source IP addresses
      dips = attrs.dips or [ ]; # destination IP addresses
      log = attrs.log or false;
      logLimit = attrs.logLimit or "rate 300/minute burst 200 packets";
      logPrefix = attrs.logPrefix or "nftables: RULE=${safeName} ";

      # build the prerouting expression with optional source and destination IPs
      preroutingExprParts = [
        "iifname ${mkSet iifs}"
      ]
      ++ (if sips != [ ] then [ (mkFieldMatch "ip saddr" sips) ] else [ ])
      ++ (if dips != [ ] then [ (mkFieldMatch "ip daddr" dips) ] else [ ])
      ++ [ "${proto} dport ${toString pt}" ];

      preroutingExpr = concatStringsSep " " preroutingExprParts;
      preroutingAction = "dnat ip to ${ip}:${toString pt}";

      # generate the log line separately
      logLine = mkLog {
        name = "${name} DNAT";
        action = "dnat";
        logLimit = logLimit;
        logPrefix = logPrefix;
      };

      preroutingRule =
        if log then
          "${preroutingExpr} ${logLine}\n${preroutingExpr} ${preroutingAction} comment \"${name} DNAT\""
        else
          "${preroutingExpr} ${preroutingAction} comment \"${name} DNAT\"";
    in
    {
      preroutingRule = preroutingRule;
    };

  mkMasqRule =
    attrs:
    let
      name = if attrs ? name then attrs.name else throw "mkMasqRule: name is required";
      safeName = sanitize name;
      oifs = if attrs ? oifs then attrs.oifs else throw "mkMasqRule: oifs is required";
      sips = if attrs ? sips then attrs.sips else [ ];
      proto = attrs.proto or "";
      log = attrs.log or false;
      logLimit = attrs.logLimit or "rate 300/minute burst 200 packets";
      logPrefix = attrs.logPrefix or "nftables: MASQ=${safeName} ";

      baseExpr = concatStringsSep " " (
        [ "oifname ${mkSet oifs}" ]
        ++ (if sips != [ ] then [ "ip saddr ${mkSet sips}" ] else [ ])
        ++ (if proto != "" then [ proto ] else [ ])
      );

      # generate the log line separately
      logLine = mkLog {
        name = "${name} MASQ";
        action = "masquerade";
        logLimit = logLimit;
        logPrefix = logPrefix;
      };

      mainRule =
        if log then
          "${baseExpr} ${logLine}\n${baseExpr} masquerade comment \"${name} MASQ\""
        else
          "${baseExpr} masquerade comment \"${name} MASQ\"";
    in
    {
      postroutingRules = [ mainRule ];
    };

  defaultFilterInputRules = [
    {
      name = "loopback";
      expr = "iif lo";
      action = "accept";
    }
    {
      name = "established related";
      expr = "ct state established,related";
      action = "accept";
    }
    {
      name = "new non syn";
      expr = "tcp flags != syn ct state new";
      action = "drop";
      log = true;
    }
    {
      name = "invalid fin syn";
      expr = "tcp flags & (fin|syn) == (fin|syn)";
      action = "drop";
      log = true;
    }
    {
      name = "invalid syn rst";
      expr = "tcp flags & (syn|rst) == (syn|rst)";
      action = "drop";
      log = true;
    }
    {
      name = "weird flags 1";
      expr = "tcp flags & (fin|syn|rst|psh|ack|urg) < (fin)";
      action = "drop";
      log = true;
    }
    {
      name = "weird flags 2";
      expr = "tcp flags & (fin|syn|rst|psh|ack|urg) == (fin|psh|urg)";
      action = "drop";
      log = true;
    }
    {
      name = "invalid state";
      expr = "ct state invalid";
      action = "drop";
      log = true;
    }
    {
      name = "icmp4 echo";
      expr = "ip protocol icmp icmp type { echo-reply, echo-request } limit rate 2000/second";
      action = "accept";
    }
    {
      name = "icmp4 other";
      expr = "ip protocol icmp";
      action = "accept";
    }
    {
      name = "icmp6 echo";
      expr = "icmpv6 type { echo-reply, echo-request } limit rate 2000/second";
      action = "accept";
    }
    {
      name = "icmp6 other";
      expr = "meta l4proto { icmpv6 }";
      action = "accept";
    }
    {
      name = "traceroute udp";
      expr = "udp dport 33434-33524 limit rate 500/second";
      action = "accept";
    }
  ];

  defaultFilterForwardRules = [
    {
      name = "icmp";
      proto = "icmp";
      action = "accept";
    }

    {
      name = "established related";
      expr = "ct state established,related";
      action = "accept";
    }
    {
      name = "accept dnat";
      expr = "ct status dnat";
      action = "accept";
      log = true;
    }
  ];

  defaultFilterOutputRules = [ ];

  defaultManglePostroutingRules =
    mssClamp:
    if mssClamp.enable then
      [
        {
          name = "mss clamp";
          expr = "tcp flags & (syn | rst) == syn tcp option maxseg size set ${mssClamp.mss}";
          action = "continue";
        }
      ]
    else
      [ ];

  baseline =
    {
      filterCounters ? [ ],
      mangleCounters ? [ ],
      dnatRules ? [ ],
      masqRules ? [ ],
      mssClamp ? {
        enable = true;
        mss = "rt mtu";
      },
      extraRawPreRoutingRules ? [ ],
      extraManglePreRoutingRules ? [ ],
      extraManglePostRoutingRules ? [ ],
      extraMangleForwardRules ? [ ],
      prependFilterForwardRules ? [ ],
      extraFilterInputRules ? [ ],
      extraFilterForwardRules ? [ ],
      extraFilterOutputRules ? [ ],
      extraNATPreRoutingRules ? [ ],
      extraNATPostRoutingRules ? [ ],
    }:
    ''
      table ip raw {
        chain prerouting {
          type filter hook prerouting priority -300;
          ${join (map mkRule extraRawPreRoutingRules)}
        }
      }

      table ip mangle {
        ${optionalString (mangleCounters != [ ]) (
          join (map (c: "counter ${c.name} { comment \"${c.comment or c.name}\" }") mangleCounters)
        )}

        chain prerouting {
          type filter hook prerouting priority -150;
          ${join (map mkRule extraManglePreRoutingRules)}
        }

        chain forward {
          type filter hook forward priority 0;
          ${join (map mkRule extraMangleForwardRules)}
        }

        chain postrouting {
          type filter hook postrouting priority 100;
          ${join (map mkRule (defaultManglePostroutingRules mssClamp))}
          ${join (map mkRule extraManglePostRoutingRules)}
        }
      }

      table inet filter {
        ${optionalString (filterCounters != [ ]) (
          join (map (c: "counter ${c.name} { comment \"${c.comment or c.name}\" }") filterCounters)
        )}

        chain input {
          type filter hook input priority 0; policy drop
          ${join (map mkRule defaultFilterInputRules)}
          ${join (map mkRule extraFilterInputRules)}
          ${mkRule {
            name = "default input deny";
            action = "drop";
            log = true;
          }}
        }

        chain output {
          type filter hook output priority 0; policy accept
          ${join (map mkRule defaultFilterOutputRules)}
          ${join (map mkRule extraFilterOutputRules)}
        }

        chain forward {
          type filter hook forward priority 0; policy drop
          ${join (map mkRule prependFilterForwardRules)}
          ${join (map mkRule defaultFilterForwardRules)}
          ${join (map mkRule extraFilterForwardRules)}
          ${mkRule {
            name = "default forward deny";
            action = "drop";
            log = true;
          }}
        }
      }

      table inet nat {
        chain prerouting {
          type nat hook prerouting priority -100;
          ${join (map (r: r.preroutingRule) dnatRules)}
          ${join (map mkRule extraNATPreRoutingRules)}
        }

        chain postrouting {
          type nat hook postrouting priority 100;
          ${join (builtins.concatMap (r: r.postroutingRules) masqRules)}
          ${join (map mkRule extraNATPostRoutingRules)}
        }
      }
    '';
in
{
  options.et42.router.nftables = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable nftables.";
    };

    filterCounters = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Named counters for inet filter table. Each counter should have a 'name' and optional 'comment'.";
    };

    mangleCounters = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Named counters for ip mangle table. Each counter should have a 'name' and optional 'comment'.";
    };

    extraRawPreRoutingRules = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Raw prerouting rules.";
    };
    extraManglePreRoutingRules = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Mangle prerouting rules.";
    };
    extraManglePostRoutingRules = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Mangle postrouting rules.";
    };
    extraMangleForwardRules = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Mangle forward rules.";
    };

    mssClamp = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable MSS clamping in mangle forward chain.";
      };
      mss = lib.mkOption {
        type = lib.types.str;
        default = "rt mtu";
        description = "MSS value to clamp to. Use 'rt mtu' for dynamic route MTU or a fixed value like '1380'.";
      };
    };

    extraFilterInputRules = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Filter input rules";
    };
    extraFilterOutputRules = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Filter output rules";
    };
    prependFilterForwardRules = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Filter forward rules (prepended before default rules like established/related)";
    };
    extraFilterForwardRules = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Filter forward rules";
    };

    extraNATPreRoutingRules = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "NAT prerouting rules";
    };
    extraNATPostRoutingRules = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "NAT postrouting rules";
    };

    dnat = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "List of DNAT definitions: { name, iifs, oifs, ip, pt, proto?, sips?, dips?, log? }.";
    };
    masq = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "List of MASQ definitions: { name, oifs, sips?, proto?, log? }.";
    };

    mkRule = lib.mkOption {
      type = lib.types.functionTo lib.types.str;
      default = mkRule;
      description = "Generate a filter rule.";
    };
    mkDnatRule = lib.mkOption {
      type = lib.types.functionTo lib.types.attrs;
      default = mkDnatRule;
      description = "Generate a DNAT rule.";
    };
    mkMasqRule = lib.mkOption {
      type = lib.types.functionTo lib.types.attrs;
      default = mkMasqRule;
      description = "Generate a MASQ rule.";
    };
  };

  config = lib.mkIf config.et42.router.nftables.enable {
    networking.firewall.enable = false;
    networking.nat.enable = false;
    services.openssh.openFirewall = false;

    networking.nftables.enable = true;

    networking.nftables.ruleset = baseline {
      filterCounters = config.et42.router.nftables.filterCounters;
      mangleCounters = config.et42.router.nftables.mangleCounters;
      mssClamp = config.et42.router.nftables.mssClamp;
      extraRawPreRoutingRules = config.et42.router.nftables.extraRawPreRoutingRules;

      extraManglePreRoutingRules = config.et42.router.nftables.extraManglePreRoutingRules;
      extraManglePostRoutingRules = config.et42.router.nftables.extraManglePostRoutingRules;
      extraMangleForwardRules = config.et42.router.nftables.extraMangleForwardRules;

      extraFilterInputRules = config.et42.router.nftables.extraFilterInputRules;
      prependFilterForwardRules = config.et42.router.nftables.prependFilterForwardRules;
      extraFilterForwardRules = config.et42.router.nftables.extraFilterForwardRules;
      extraFilterOutputRules = config.et42.router.nftables.extraFilterOutputRules;

      extraNATPreRoutingRules = config.et42.router.nftables.extraNATPreRoutingRules;
      extraNATPostRoutingRules = config.et42.router.nftables.extraNATPostRoutingRules;

      dnatRules = map mkDnatRule config.et42.router.nftables.dnat;
      masqRules = map mkMasqRule config.et42.router.nftables.masq;
    };
  };
}
