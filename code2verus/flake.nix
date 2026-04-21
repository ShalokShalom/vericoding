{
  description = "code2verus — reproducible dev shell and build for the Dafny/Verus/F# translation pipeline";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # Pin a recent rust-overlay for Verus builds (Verus requires nightly Rust)
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };

        # ---------------------------------------------------------------------------
        # Python environment
        # Mirrors the dependencies in pyproject.toml exactly.
        # ---------------------------------------------------------------------------
        python = pkgs.python312;

        pythonEnv = python.withPackages (ps: with ps; [
          # runtime deps
          datasets
          pydantic
          python-dotenv
          pyyaml
          logfire
          # pydantic-ai is not yet in nixpkgs; installed via pip into the venv
          # (see shellHook below)

          # dev deps
          pytest
          pytest-asyncio
          pyright
          ruff
        ]);

        # ---------------------------------------------------------------------------
        # Rust / Verus
        # Verus requires a specific nightly toolchain; we pin a recent one.
        # The actual verus binary is built outside Nix (see docs/dev-setup.md);
        # we only provide the correct Rust toolchain here so `cargo build` works.
        # ---------------------------------------------------------------------------
        rustToolchain = pkgs.rust-bin.nightly."2024-11-01".default.override {
          extensions = [ "rust-src" "rustfmt" "clippy" ];
        };

        # ---------------------------------------------------------------------------
        # .NET 9 SDK — for the F# backend (dotnet build verification oracle)
        # ---------------------------------------------------------------------------
        dotnetSdk = pkgs.dotnet-sdk_9;

        # ---------------------------------------------------------------------------
        # Dafny — verification tool
        # nixpkgs ships a recent Dafny; pin via nixos-unstable for latest.
        # ---------------------------------------------------------------------------
        dafny = pkgs.dafny;

        # ---------------------------------------------------------------------------
        # Dev shell
        # ---------------------------------------------------------------------------
        devShell = pkgs.mkShell {
          name = "code2verus";

          packages = [
            # Python
            pythonEnv
            pkgs.uv           # fast venv / lockfile manager

            # Rust toolchain (for Verus builds)
            rustToolchain
            pkgs.cargo-nextest

            # .NET / F#
            dotnetSdk
            pkgs.fsautocomplete  # LSP for F# dev

            # Dafny
            dafny

            # General tooling
            pkgs.git
            pkgs.jq
            pkgs.ripgrep
            pkgs.fd
            pkgs.just            # task runner (Justfile)
          ];

          shellHook = ''
            echo ""
            echo "  code2verus dev shell"
            echo "  ────────────────────────────────────────────────────"
            echo "  Python  : $(python --version)"
            echo "  Dafny   : $(dafny --version 2>/dev/null | head -1 || echo 'not found')"
            echo "  .NET    : $(dotnet --version)"
            echo "  Rust    : $(rustc --version)"
            echo ""

            # Create a local venv for packages not yet in nixpkgs (pydantic-ai, logfire).
            if [ ! -d .venv ]; then
              echo "  → Creating .venv with uv ..."
              uv venv .venv --python python3.12
            fi
            source .venv/bin/activate

            # Install / sync editable package + extras not in nixpkgs.
            # This is fast after the first run because uv caches wheels.
            uv pip install -e ".[dev]" --quiet 2>/dev/null || true

            echo "  Ready. Run: code2verus --help"
            echo ""
          '';

          # Expose Dafny path so config.yml can pick it up via the env var
          DAFNY_PATH = "${dafny}/bin/dafny";
          DOTNET_ROOT = "${dotnetSdk}";

          # Suppress .NET telemetry in the shell
          DOTNET_CLI_TELEMETRY_OPTOUT = "1";
          DOTNET_NOLOGO = "1";
        };

        # ---------------------------------------------------------------------------
        # Package: the code2verus Python application
        # Built with buildPythonApplication so `nix build` produces a runnable output.
        # pydantic-ai is fetched from PyPI via fetchPypi; adjust hashes as needed.
        # ---------------------------------------------------------------------------
        code2verus = python.pkgs.buildPythonApplication {
          pname = "code2verus";
          version = "0.1.0";
          src = ./.;
          format = "pyproject";

          build-system = with python.pkgs; [ hatchling ];

          propagatedBuildInputs = with python.pkgs; [
            datasets
            pydantic
            python-dotenv
            pyyaml
            logfire
            # pydantic-ai: add once packaged in nixpkgs, or use fetchPypi override
          ];

          # Skip the test suite during `nix build`; run tests via `nix develop` + pytest
          doCheck = false;

          meta = with pkgs.lib; {
            description = "Translate Dafny/Verus/Lean code via AI with verified output";
            license = licenses.mit;
            maintainers = [ ];
            mainProgram = "code2verus";
          };
        };

      in {
        # `nix develop` — full dev shell
        devShells.default = devShell;

        # `nix build` — produce the code2verus binary
        packages.default = code2verus;
        packages.code2verus = code2verus;

        # `nix run` — run directly without installing
        apps.default = flake-utils.lib.mkApp {
          drv = code2verus;
          name = "code2verus";
        };

        # Expose individual tools for downstream consumers
        packages.dafny = dafny;
        packages.dotnetSdk = dotnetSdk;
        packages.rustToolchain = rustToolchain;
      }
    );
}
