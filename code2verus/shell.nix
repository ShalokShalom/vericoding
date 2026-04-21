# Reproducible dev shell for code2verus.
# Pinned via npins — no flakes, no channels required.
#
# Usage:
#   nix-shell          # enter the dev shell
#   nix-shell --run 'code2verus --help'
#
# To update all pins:
#   nix-shell -p npins --run 'npins update'
#   git add npins/sources.json && git commit -m 'npins: update'

let
  sources = import ./npins;

  rustOverlay = import sources.rust-overlay;

  pkgs = import sources.nixpkgs {
    overlays = [ rustOverlay ];
    config   = {};
  };

  # ---------------------------------------------------------------------------
  # Python 3.12 environment
  # Mirrors runtime deps from pyproject.toml.
  # pydantic-ai is not yet in nixpkgs — installed into .venv via uv (see shellHook).
  # ---------------------------------------------------------------------------
  python = pkgs.python312;

  pythonEnv = python.withPackages (ps: with ps; [
    datasets
    pydantic
    python-dotenv
    pyyaml
    logfire
    # dev extras
    pytest
    pytest-asyncio
    pyright
    ruff
  ]);

  # ---------------------------------------------------------------------------
  # Rust nightly — Verus requires a specific nightly toolchain.
  # The Verus binary itself is built manually; see docs/dev-setup.md.
  # ---------------------------------------------------------------------------
  rustToolchain = pkgs.rust-bin.nightly."2024-11-01".default.override {
    extensions = [ "rust-src" "rustfmt" "clippy" ];
  };

in pkgs.mkShell {
  name = "code2verus";

  packages = [
    # Python
    pythonEnv
    pkgs.uv

    # Rust (for Verus builds)
    rustToolchain
    pkgs.cargo-nextest

    # .NET 9 — F# backend / dotnet build verification oracle
    pkgs.dotnet-sdk_9
    pkgs.fsautocomplete

    # Dafny — source language verifier
    pkgs.dafny

    # General tooling
    pkgs.git
    pkgs.jq
    pkgs.ripgrep
    pkgs.fd
    pkgs.just
  ];

  # Environment variables read by config.yml and dotnet tooling
  DAFNY_PATH   = "${pkgs.dafny}/bin/dafny";
  DOTNET_ROOT  = "${pkgs.dotnet-sdk_9}";
  DOTNET_CLI_TELEMETRY_OPTOUT = "1";
  DOTNET_NOLOGO = "1";

  shellHook = ''
    echo ""
    echo "  code2verus dev shell"
    echo "  ────────────────────────────────────────────────────"
    echo "  Python : $(python --version)"
    echo "  Dafny  : $(dafny --version 2>/dev/null | head -1 || echo 'not found')"
    echo "  .NET   : $(dotnet --version)"
    echo "  Rust   : $(rustc --version)"
    echo ""

    # Create a local venv for packages not yet in nixpkgs (pydantic-ai).
    if [ ! -d .venv ]; then
      echo "  → Creating .venv with uv ..."
      uv venv .venv --python python3.12
    fi
    source .venv/bin/activate

    # Sync editable install + extras not in nixpkgs.
    uv pip install -e ".[dev]" --quiet 2>/dev/null || true

    echo "  Ready. Run: code2verus --help"
    echo ""
  '';
}
