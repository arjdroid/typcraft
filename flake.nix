{
  description = "Elm + Bun + Rust development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        # Rust with wasm32 target
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          targets = [ "wasm32-unknown-unknown" ];
        };

        elmPackages = pkgs.elmPackages;

        buildInputs = with pkgs; [
          # Elm tools
          elmPackages.elm
          elmPackages.elm-format
          elmPackages.elm-language-server

          # JS runtime
          bun

          # Favicon build tools
          typst
          imagemagick

          # Rust + WASM tools
          rustToolchain
          wasm-pack
          wasm-bindgen-cli
          binaryen # for wasm-opt
          # Due to my unfamiliarity with Rust/WASM tooling,
          # Claude has chosen these.
          # TODO maybe change these

        ];

      in {
        # Development shell
        devShells.default = pkgs.mkShell {
          inherit buildInputs;

          shellHook = ''
            echo "Elm + Bun + Rust development environment"
            echo "Elm version: $(elm --version)"
            echo "Bun version: $(bun --version)"
            echo "Rust version: $(rustc --version)"
            echo ""
            echo "Commands:"
            echo "  make build   - Build WASM and Elm outputs"
            echo "  make dev     - Run bunx dev server"
          '';
        };

        # Default package (build everything)
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "typst-math-preview";
          version = "0.1.0";

          src = ./.;

          buildInputs = buildInputs;

          buildPhase = ''
            export HOME=$TMPDIR

            # Build WASM
            cd wasm
            wasm-pack build --target web --out-dir ../public/pkg
            cd ..

            # Build Elm
            elm make src/Main.elm --optimize --output=public/elm.js
          '';

          installPhase = ''
            mkdir -p $out
            cp -r public/* $out/
          '';
        };
      }
    );
}
