# convert-object - AI coding-assistant plugin

Package-specific skills that make Claude Code and OpenAI Codex reliable when
working with the [`convert_object`](https://pub.dev/packages/convert_object)
Dart package. The skills encode the package's exact API signatures and parsing
rules (verified against source), which coding agents otherwise misremember.

This plugin contains **instructions and reference documents only**: no hooks,
no MCP servers, no executable scripts, no network access, no telemetry.

## Included skills

| Skill | Use it for |
|---|---|
| `parse-with-convert-object` | Writing `fromJson`/model parsing: choosing the right API surface, strict vs `try*` vs `defaultValue`, collections, enums, `alternativeKeys`, `tryGetRaw` |
| `configure-convert-object` | `ConvertConfig` (global + zone-scoped), locale/format defaults, `BoolOptions` truthy/falsy tokens, `UriOptions`, `TypeRegistry` custom types, `onException` telemetry |
| `debug-convert-object` | `ConversionException` forensics and the exact parsing-rule tables: epoch second/millisecond rules, locale-ambiguous dates, timezone semantics, bool tokens, URI coercion, JSON auto-decode boundaries |
| `migrate-from-dart-helper-utils` | Moving a project off `dart_helper_utils` <= 5.x conversion APIs (`ConvertObject`, `toString1`, `ParsingException`, bare top-level `toX`) onto `convert_object` |
| `upgrade-convert-object` | Version-aware upgrade audits: 1.0.0-dev.x -> stable checklist, pre-1.1.0 -> 1.1.x `alternativeKeys` behavior-change audit |

## Install - Claude Code

From within Claude Code:

```
/plugin marketplace add omar-hanafy/convert_object
/plugin install convert-object@convert-object-tools
```

Or from the shell:

```bash
claude plugin marketplace add omar-hanafy/convert_object
claude plugin install convert-object@convert-object-tools
```

Skills activate automatically when relevant, or explicitly:
`/convert-object:parse-with-convert-object`. Start a new session (or run
`/reload-plugins`) if a just-installed skill does not appear.

## Install - OpenAI Codex

Codex CLI and the ChatGPT desktop app (Codex/Work modes) support plugins:

```bash
codex plugin marketplace add omar-hanafy/convert_object
codex plugin add convert-object@convert-object-tools
```

Start a new Codex session afterwards; bundled skills load at session start.
Invoke explicitly by mentioning a skill (e.g. `$parse-with-convert-object`)
or via `/skills`.

The Codex IDE extension does not support plugins. There, install individual
skills with the built-in `$skill-installer` skill, for example:

```
$skill-installer install from repo omar-hanafy/convert_object
path tooling/ai/convert-object/skills/parse-with-convert-object
```

## Example prompts

- "Write a fromJson for this payload using convert_object; ids arrive as
  strings and created_at is epoch seconds."
- "Why does Convert.toDateTime('02/03/2024', autoDetectFormat: true) give a
  different month on CI?"
- "Make convert_object accept 'oui'/'non' as booleans app-wide."
- "Migrate this file from dart_helper_utils ConvertObject to convert_object."
- "Is it safe to bump convert_object from 1.0.4 to 1.1.0 in this repo?"

## Compatibility

- Package: convert_object 1.x (skills document 1.1.x behavior and call out
  the 1.0.x differences explicitly).
- Claude Code: plugins with marketplace support (v2.x).
- Codex: CLI / desktop app with plugin support (codex-cli 0.144+); IDE
  extension via skill-installer as above.

## Updating / removing

- Claude Code: `/plugin update convert-object@convert-object-tools`, remove
  with `/plugin uninstall convert-object@convert-object-tools`.
- Codex: `codex plugin marketplace upgrade convert-object-tools` then a new
  session; remove with `codex plugin remove convert-object`.

## Permissions

The skills only instruct the agent to read project files it already has
access to and run the standard Dart toolchain (`dart analyze`, `dart test`,
`grep`) under the client's normal permission prompts. Nothing in this plugin
executes on its own.

## For maintainers of this repository

- Canonical source: `tooling/ai/convert-object/` (skills are shared verbatim
  by both ecosystems; manifests live in `.claude-plugin/` and
  `.codex-plugin/`).
- Catalogs: `.claude-plugin/marketplace.json` and
  `.agents/plugins/marketplace.json` at the repository root.
- Versioning: both plugin manifests must equal the pubspec version -
  enforced by `dart run tool/validate_agent_plugin.dart` (runs in CI).
- Every future breaking package release must add a hop to
  `upgrade-convert-object` (or a dedicated `migrate-vX-to-vY` skill for large
  migrations) before the release is tagged.
- Local validation: `claude plugin validate .` (marketplace) and
  `claude plugin validate tooling/ai/convert-object` (plugin), plus the Dart
  validator above.
- None of this tree ships in the pub.dev archive (see `.pubignore`);
  distribution is repository-hosted only.
