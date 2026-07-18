# AI Coding-Assistant Plugin - Design

Date: 2026-07-18
Status: implemented with release 1.1.1
Scope: installable, package-specific AI-assistant support for Claude Code and
OpenAI Codex, distributed from this repository; plus repo-local maintainer
guidance. No Dart runtime API changes.

## Evidence-based capability model

### Personas

1. Package consumers: Dart/Flutter developers parsing dynamic data (JSON
   payloads, maps, user input) into typed values, usually in `fromJson`-style
   model layers.
2. Consumers debugging a failed or wrong conversion (a thrown
   `ConversionException`, a date off by hours/decades, a bool silently false).
3. Consumers arriving from `dart_helper_utils` (the documented predecessor of
   this package) or upgrading across convert_object versions.
4. Maintainers evolving the package (API parity across five surfaces, docs
   philosophy, gated release flow).

### Task evidence

- Writing model parsing: README "Advanced usage & recipes", `example/`,
  800-test suite organized by API area.
- Choosing strict `to*` vs `tryTo*` vs `defaultValue`: dedicated README section
  ("Strict vs try vs default"); `toBool` is a documented exception (never
  throws).
- Date parsing: 388-line `dates.dart` with epoch digit-count heuristics, a
  12-digit `yyyyMMddHHmm` guard, locale-dependent slashed-date ambiguity,
  calendar-vs-instant timezone semantics; README dedicates a deep-dive.
- Config: 577-line `convert_config.dart` with zone-scoped overrides, an
  override bitmask (`ConvertConfig.overrides` vs plain constructor), and
  `TypeRegistry` for custom `toType<T>` parsers.
- API parity is a real maintainer hazard: PR #22 "Hotfix optional argument
  parity" exists because the five public surfaces (Convert, Converter,
  top-level functions, Map extensions, Iterable extensions) drifted.
- Migrations: README documents two real paths - "Migration beta to stable"
  (1.0.0-dev.x behavioral changes) and "Migration from dart_helper_utils".
  CHANGELOG 1.1.0 documents the `alternativeKeys` first-non-null behavior
  change affecting every typed map getter.
- Baseline probes (agents without skills, knowledge-only) confirmed agents
  hallucinate plausible-but-wrong API for this package - the strongest evidence
  that reference-grade skills add value over the README alone.

## Chosen capabilities

### Installable plugin `convert-object` (consumer-facing), five skills

1. `parse-dynamic-data` - writing model/`fromJson` parsing: API-surface
   selection, strict/try/default decision, alternativeKeys/alternativeIndices,
   nested navigation, collections with element converters, enums, tryGetRaw.
   Reference: full API quick-reference (all five surfaces).
2. `configure-conversions` - `ConvertConfig` global vs scoped semantics,
   options bundles, `TypeRegistry`, `onException` telemetry hook.
3. `debug-conversions` - `ConversionException` forensics plus the pitfall
   catalog (epoch digit rules, locale-ambiguous dates, bool token sets, URI
   coercion, JSON auto-decode boundaries).
4. `migrate-from-dart-helper-utils` - moving a project off DHU's ConvertObject
   API onto convert_object, with behavior-difference audit.
5. `upgrade-convert-object` - version-aware upgrade audit: 1.0.0-dev.x to
   stable behavioral checklist; pre-1.1.0 to 1.1.0+ `alternativeKeys`
   present-but-null audit.

Each skill is self-contained (its references live inside its own directory) so
per-skill installation on any client cannot break cross-file links.

### Repo-local maintainer support (not in the plugin)

- `AGENTS.md` (canonical) + `CLAUDE.md` (same content for Claude Code):
  validation commands, the five-surface parity invariant, docs philosophy
  pointer (docs_guide.md), release flow (version bump PR, auto-tag, trusted
  publishing), plugin-maintenance rule: every future breaking release must ship
  a versioned migration skill before tagging.
- `.claude/skills/add-conversion-api/` - repo-local maintainer skill for
  adding/changing a conversion API across all five surfaces + tests + docs.
- `tool/validate_agent_plugin.dart` - deterministic validation (JSON/frontmatter
  syntax, kebab-case, version sync with pubspec across both manifests and both
  catalogs, referenced files exist, no `../`/absolute paths, pubignore covers
  the plugin tree). Wired into CI.

### Rejected capabilities (with reasons)

- Hooks: no deterministic lifecycle need; no generated files to protect;
  auto-running analyzers in consumer projects would be invasive, not
  package-specific.
- MCP server / connectors: no external system; everything is expressible as
  instructions + file reads; would add install burden and review surface.
- Custom agents: no narrow role the default agent + skill instructions cannot
  do; bulk scans are delegated to the clients' built-in explore subagents.
- LSP / monitors: Dart already has full language intelligence; no continuous
  state to observe.
- A "Flutter integration" skill: package is pure Dart; nothing
  platform-specific exists in the repo.

## Distribution architecture

Single dual-target plugin root, one canonical copy of every skill:

    tooling/ai/convert-object/
      .claude-plugin/plugin.json      # Claude Code manifest
      skills/<skill-name>/SKILL.md    # shared canonical skills (+ references/)
      README.md                       # plugin docs (both ecosystems)
    .claude-plugin/marketplace.json   # Claude Code catalog, repo root

Codex distribution: see "Codex mechanism" below (finalized from the July 2026
Codex CLI + official docs research; do not assume parity with Claude).

pub.dev archive: the entire `tooling/` tree and repo-root catalogs are excluded
via `.pubignore`. The pub archive must contain either the complete plugin or
none of it; we ship none of it and install from the repository.

## Versioning

- Package: 1.1.1 (patch: repository tooling + documentation, no runtime API
  change).
- Plugin manifests and marketplace entries: 1.1.1, kept aligned with pubspec by
  `tool/validate_agent_plugin.dart` in CI.

## Codex mechanism (verified against codex-cli 0.144.5 + official docs, July 2026)

- Codex skills use the same agentskills.io SKILL.md standard as Claude
  (required frontmatter: `name` matching the directory, `description`). One
  canonical skills tree therefore serves both clients unmodified.
- Codex has stable plugin + marketplace support: plugin manifest at
  `.codex-plugin/plugin.json` in the plugin root; repo catalog at
  `.agents/plugins/marketplace.json` with object sources
  (`{"source": "local", "path": "./..."}`).
- Install flow: `codex plugin marketplace add omar-hanafy/convert_object`,
  then `codex plugin add convert-object@convert-object-tools`; bundled skills
  appear in the next session.
- Plugins are supported in Codex CLI and the ChatGPT desktop app (Work/Codex
  modes), NOT in the IDE extension; IDE users can install individual skills
  via the built-in `$skill-installer` system skill
  (`--repo omar-hanafy/convert_object --path tooling/ai/convert-object/skills/<name>`).
- Skill frontmatter is kept to the portable core (`name`, `description`) so
  neither client sees vendor-specific extensions.

Final names: plugin `convert-object`, marketplace `convert-object-tools` in
both catalogs, skills `parse-with-convert-object`, `configure-convert-object`,
`debug-convert-object`, `migrate-from-dart-helper-utils`,
`upgrade-convert-object`.

## Baseline evidence (RED probes, knowledge-only agents without skills)

- Parsing probe: agent invented `altKeys:` (real: `alternativeKeys:`), called
  `getEnum('role', Role.values)` (real API requires `parser:`, and
  case-insensitivity requires `Role.values.parserCaseInsensitive`), cited a
  nonexistent `detailedReport` (real: `fullReport()`), and assumed
  `toString()` prints the full report (it is concise by design). It did know
  `tryGetRaw` and JSON-string list decoding.
- These exact failures are the correction targets emphasized in the skills.
