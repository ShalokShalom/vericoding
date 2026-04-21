# dev setup

This project uses [npins](https://github.com/andir/npins) for reproducible, pinned Nix builds — no flakes, no channels, no experimental features required.

## prerequisites

- Any Nix installation (stable Nix is fine)
- No other dependencies — Nix handles Python, .NET, Dafny, and the Rust toolchain

## quick start

```bash
cd code2verus
nix-shell          # enter the dev shell
code2verus --help  # confirm the tool is available
```

The first `nix-shell` will take a few minutes to download and build the environment. Subsequent runs are instant.

## file layout

```
code2verus/
├── shell.nix          ← dev shell (nix-shell)
├── default.nix        ← buildable package (nix-build)
└── npins/
    ├── default.nix    ← npins fetcher boilerplate (do not edit)
    └── sources.json   ← pinned revisions + hashes (the lock file)
```

## what the shell provides

| tool | version / source | purpose |
|---|---|---|
| Python 3.12 | nixpkgs unstable | runtime |
| uv | nixpkgs | venv + package manager |
| Dafny | nixpkgs | source language verification |
| .NET 9 SDK | nixpkgs | F# backend (`dotnet build` oracle) |
| fsautocomplete | nixpkgs | F# LSP |
| Rust nightly 2024-11-01 | rust-overlay | Verus toolchain |
| cargo-nextest | nixpkgs | fast Rust test runner |
| just | nixpkgs | task runner |

## environment variables set automatically

```
DAFNY_PATH                    — path to dafny binary (read by config.yml)
DOTNET_ROOT                   — .NET SDK root
DOTNET_CLI_TELEMETRY_OPTOUT=1
DOTNET_NOLOGO=1
```

## Verus binary

Verus is not yet packaged in nixpkgs. Build it once manually:

```bash
# inside nix-shell — the correct Rust nightly is already on PATH
git clone https://github.com/verus-lang/verus ~/verus
cd ~/verus/source
./tools/get-z3.sh
vargo build --release
# binary lands at ~/verus/source/target-verus/release/verus
```

Then in `code2verus/config.yml`:

```yaml
verus_path: /home/you/verus/source/target-verus/release/verus
```

Or set `VERUS_PATH` in `.env`.

## pydantic-ai

`pydantic-ai` is not yet packaged in nixpkgs. The shell hook installs it automatically into a local `.venv` via `uv pip install -e .[dev]`. This is the only step that requires internet access on first run.

## updating pins

```bash
# update all pins to latest
nix-shell -p npins --run 'npins update'

# update only nixpkgs
nix-shell -p npins --run 'npins update nixpkgs'

git add npins/sources.json
git commit -m 'npins: update'
```

## nix-build

Build the code2verus package as a Nix derivation:

```bash
nix-build -A code2verus
./result/bin/code2verus --help
```

## ci

`shell.nix` and `default.nix` work directly with standard Nix CI setups:

```yaml
# .github/workflows/ci.yml (example)
- uses: DeterminateSystems/nix-installer-action@main
- uses: DeterminateSystems/magic-nix-cache-action@main
- run: nix-shell --run 'pytest'
- run: nix-build -A code2verus
```

No `--extra-experimental-features` flag needed anywhere.

## initialising pins on a fresh fork

If you fork this repo and want to reinitialise the pins from scratch:

```bash
nix-shell -p npins --run 'npins init --bare'
nix-shell -p npins --run 'npins add github NixOS nixpkgs --branch nixos-unstable'
nix-shell -p npins --run 'npins add github oxalica rust-overlay'
```

This regenerates `npins/sources.json` with fresh hashes.
