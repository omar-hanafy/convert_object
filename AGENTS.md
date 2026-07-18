# convert_object - agent guide (maintainers)

Pure-Dart type-conversion library (no Flutter dependency). Public API lives in
`lib/convert_object.dart` exports; the engine is
`lib/src/core/convert_object_impl.dart`.

## Validation gates (run before claiming any change done)

```bash
dart format --output=none --set-exit-if-changed .
dart analyze .                       # public_member_api_docs is an ERROR here
dart test
dart run tool/validate_agent_plugin.dart   # AI plugin/marketplace consistency
dart pub publish --dry-run           # must stay at 0 warnings
```

CI additionally requires a PERFECT pana score (160/160) on PRs; avoid changes
that cost points (missing doc comments, dependency issues, format drift).

## API parity invariant

Every conversion capability exists on five surfaces that must stay in sync:
`Convert` static facade, top-level `convertToX` functions, fluent `Converter`,
Map extensions (`getX`/`tryGetX`), Iterable extensions. Changing or adding one
without the others is a bug (see PR #22 "Hotfix optional argument parity").
Follow `.claude/skills/add-conversion-api/SKILL.md` for the full checklist
(readable as a plain file from any agent).

## Conventions

- Documentation philosophy: `docs_guide.md` (behavior-first Dartdoc, resolvable
  `[...]` links only, "See also" cross-refs). Doc comments are analyzer-gated.
- Tests: conventions in `test/README.md` - isolate `ConvertConfig` with
  snapshot/restore, `Intl.defaultLocale = 'en_US'` + `initTestIntl()`, assert
  UTC instants rather than local times.
- Never use the em-dash character in this repo's files; use '-' instead.

## Release process

1. Version bump lands via PR to `main` (branch protection requires checks
   "Test on stable", "Test on beta", "pub-dry-run"; no direct pushes).
2. `CHANGELOG.md` entry + `pubspec.yaml` version in the same PR
   (label-release workflow tags the PR "release" automatically).
3. Merge -> auto-release workflow creates tag `convert_object-vX.Y.Z` + GitHub
   release; the tag triggers trusted publishing to pub.dev (OIDC, no manual
   credentials). Never re-use or overwrite an existing tag.
4. Stable versions only on `main`; `-dev` pre-releases only on `dev`.

## AI assistant plugin (Claude Code + Codex)

- Canonical tree: `tooling/ai/convert-object/` (one shared `skills/` set;
  manifests `.claude-plugin/plugin.json` + `.codex-plugin/plugin.json`).
  Catalogs: `.claude-plugin/marketplace.json` and
  `.agents/plugins/marketplace.json` at repo root.
- Both plugin manifests' `version` must equal `pubspec.yaml` version - bump
  them together (CI enforces via `tool/validate_agent_plugin.dart`).
- Skill facts must match the source; when changing parsing behavior, update
  the affected skill/reference files in the same PR.
- Any future BREAKING release must ship a migration hop in
  `tooling/ai/convert-object/skills/upgrade-convert-object/` (or a dedicated
  `migrate-vX-to-vY` skill for large migrations) before tagging.
- The plugin tree, catalogs, `tool/`, `docs/`, and this file are excluded from
  the pub.dev archive via `.pubignore` - keep the archive free of partial
  plugin content.
