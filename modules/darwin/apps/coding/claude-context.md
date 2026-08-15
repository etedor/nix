## Simplified Technical English (ASD-STE100)

Apply STE to reader-facing prose:

| Text | STE grammar | STE vocabulary |
|------|-------------|----------------|
| docs, README explanations, runbooks, guides | yes | yes (mostly) |
| user-facing error text (exceptions, CLI output, API responses, notifications) | yes | judgment — reject aerospace terms |

Leave idiomatic: docstrings, code comments, structured-log event keys.

**Grammar — apply wherever STE applies:**

- active voice; name the actor (`not logged in` → `the client is not logged in to the service`)
- simple tense, no `-ing` (`retrying in 30s` → `tries again after 30 seconds`)
- one idea per sentence; condition before command

**Vocabulary — the linter's wordlist is aerospace, not software:**

- keep software terms it flags: e.g. `failed` (not "unserviceable"), `extract` (not "remove")
- keep domain and technical names: identifiers, service names, config keys, host names
- the linter is advisory — act on grammar, weigh vocabulary, reject wrong substitutions

**Tools:**

- `ste-vale` MCP — lint prose for STE violations
- `ste-vocab` MCP — authoritative approved-word lookup before substituting
