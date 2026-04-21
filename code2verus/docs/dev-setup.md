# dev setup

This project uses [Nix flakes](https://nixos.wiki/wiki/Flakes) for a fully reproducible development environment.

## prerequisites

- Nix with flakes enabled (`nix.settings.experimental-features = ["nix-command" "flakes"]`)
- No other dependencies required — Nix handles Python, .NET, Dafny, and the Rust toolchain

## quick start

```bash
cd code2verus
nix develop          # enter the dev shell
code2verus --help    # confirm the tool is available
```

The first `nix develop` will take a few minutes to download and build the environment. Subsequent runs are instant (cached).

## what the shell provides

| tool | version / source | purpose |
|---|---|---|
| Python 3.12 | nixpkgs unstable | runtime |
| uv | nixpkgs | venv + package manager |
| Dafny | nixpkgs | source language verification |
| .NET 9 SDK | nixpkgs | F# backend (`dotnet build` oracle) |
| Rust nightly (2024-11-01) | rust-overlay | Verus toolchain |
| cargo-nextest | nixpkgs | fast test runner for Verus |
| fsautocomplete | nixpkgs | F# LSP server |
| just | nixpkgs | task runner |

## environment variables set automatically

```
DAFNY_PATH      — path to the dafny binary (read by config.yml)
DOTNET_ROOT     — .NET SDK root (read by dotnet tooling)
DOTNET_CLI_TELEMETRY_OPTOUT=1
DOTNET_NOLOGO=1
```

These match what `config.yml` expects, so no manual `.env` edits are needed for the standard toolchain.

## Verus binary

Verus itself is not yet packaged in nixpkgs. Build it once and point `config.yml` at the binary:

```bash
# inside nix develop — the correct Rust nightly is already on PATH
git clone https://github.com/verus-lang/verus ~/verus
cd ~/verus/source
./tools/get-z3.sh
vargo build --release
# binary is at ~/verus/source/target-verus/release/verus
```

Then in `code2verus/config.yml`:

```yaml
verus_path: /home/you/verus/source/target-verus/release/verus
```

Or set `VERUS_PATH` in your `.env` file.

## pydantic-ai

`pydantic-ai` is not yet packaged in nixpkgs. The shell hook installs it automatically into a local `.venv` via `uv pip install -e .[dev]`. This is the only step that requires internet access on first run.

## nix build

To build the code2verus package as a Nix derivation (useful for CI or deployment):

```bash
nix build
./result/bin/code2verus --help
```

## nix run

Run without installing:

```bash
nix run . -- --source-language dafny --target-language fsharp --benchmark ./benches/game
```

## ci

The flake exposes `devShells.default` and `packages.default`, which map directly to the standard NixOS/nix-action CI pattern:

```yaml
# .github/workflows/ci.yml (example)
- uses: DeterminateSystems/nix-installer-action@main
- uses: DeterminateSystems/magic-nix-cache-action@main
- run: nix develop --command pytest
- run: nix build
```

## updating the flake

```bash
nix flake update          # update all inputs to latest
nix flake update nixpkgs  # update only nixpkgs
```

After updating, commit both `flake.nix` and `flake.lock`.
