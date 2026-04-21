# Buildable package derivation for code2verus.
# Used by nix-build and CI.
#
# Usage:
#   nix-build          # produces ./result/bin/code2verus
#   nix-build -A code2verus

let
  sources = import ./npins;

  pkgs = import sources.nixpkgs {
    overlays = [];
    config   = {};
  };

  python = pkgs.python312;

in {
  code2verus = python.pkgs.buildPythonApplication {
    pname   = "code2verus";
    version = "0.1.0";
    src     = ./.;
    format  = "pyproject";

    build-system = with python.pkgs; [ hatchling ];

    propagatedBuildInputs = with python.pkgs; [
      datasets
      pydantic
      python-dotenv
      pyyaml
      logfire
      # pydantic-ai: add once packaged in nixpkgs
    ];

    # Tests require network (LLM calls) — run them via nix-shell + pytest instead.
    doCheck = false;

    meta = with pkgs.lib; {
      description = "Translate Dafny/Verus/Lean to F# and other targets via AI with verified output";
      license     = licenses.mit;
      mainProgram = "code2verus";
    };
  };

  # Expose individual tools so downstream consumers can reference them.
  dafny        = pkgs.dafny;
  dotnet-sdk   = pkgs.dotnet-sdk_9;
}
