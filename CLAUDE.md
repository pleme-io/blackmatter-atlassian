# blackmatter-atlassian — Claude Orientation

> **★★★ CSE / Knowable Construction.** This repo operates under **Constructive Substrate Engineering** — canonical specification at [`pleme-io/theory/CONSTRUCTIVE-SUBSTRATE-ENGINEERING.md`](https://github.com/pleme-io/theory/blob/main/CONSTRUCTIVE-SUBSTRATE-ENGINEERING.md). The Compounding Directive (operational rules: solve once, load-bearing fixes only, idiom-first, models stay current, direction beats velocity) is in the org-level pleme-io/CLAUDE.md ★★★ section. Read both before non-trivial changes.


One-sentence purpose: home-manager module that provisions `acli` + Rovo Dev
configs and macOS Keychain credentials from SOPS-backed token files.

## Classification

- **Archetype:** `blackmatter-component-hm-only` (home-manager module only, no
  NixOS/Darwin module, no packages, no overlay)
- **Flake shape:** driven by `substrate/lib/blackmatter-component-flake.nix`
  (see `flake.nix` — the entire outputs block is one `import` call)
- **Option namespace:** `blackmatter.components.atlassian`

## Where to look

| Intent | File |
|--------|------|
| Option schema & activation logic | `module/default.nix` |
| Rovo Dev sub-options (typed) | `module/rovodev-options.nix` |
| Flake surface (modules, checks, devShell) | `flake.nix` |
| User-facing usage | `README.md` |
| Typescape registration | `.typescape.yaml` |

## What NOT to do

- **Don't inline a custom `forAllSystems` here.** The flake goes through
  `substrate/lib/blackmatter-component-flake.nix` — if you need a new output
  shape, extend the helper, don't bypass it.
- **Don't add a package output** unless the repo genuinely produces a binary.
  `acli` itself is installed via Homebrew on macOS (see the HM module's
  `home.packages` conditional).
- **Don't hardcode site URLs, emails, or account IDs.** All consumer data goes
  through the `sites.<name>` option — keep the module generic.
- **Don't commit real API tokens.** Tokens live in SOPS-encrypted files under
  `~/.config/atlassian/<site>/` and are referenced by path only.

## Adding a new site type (e.g. Bitbucket)

1. Extend the `sites.<name>` submodule options in `module/default.nix`.
2. Write a new `mk<Service>Config` function mirroring `mkJiraConfig` /
   `mkConfluenceConfig`.
3. Add the generated file to the `home.file` mapping gated on
   `sites.<name>.<service>.enable`.
4. `nix flake check` — the `eval-hm-module` check should still pass.

## Testing

The flake exposes `checks.<system>.eval-hm-module`: a pure-evaluation smoke
test that imports the module with `enable = false` and walks the options
tree. Run with:

```bash
nix build .#checks.aarch64-darwin.eval-hm-module
```

Add targeted tests by passing `extraChecks = pkgs: { ... }` to
`mkBlackmatterFlake` in `flake.nix`.
