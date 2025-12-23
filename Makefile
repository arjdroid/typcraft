.PHONY: build dev clean deploy

# Build everything (optimized)
build: public/pkg/typst_math_svg_bg.wasm public/elm.js public/favicon.ico

# WASM module (optimized) - only rebuilds if Rust source changes
public/pkg/typst_math_svg_bg.wasm: wasm/src/lib.rs wasm/Cargo.toml wasm/Cargo.lock
	cd wasm && wasm-pack build --target web --out-dir ../public/pkg

# WASM module (fast, unoptimized) - for development
public/pkg/typst_math_svg_bg.wasm.dev: wasm/src/lib.rs wasm/Cargo.toml wasm/Cargo.lock
	cd wasm && wasm-pack build --dev --target web --out-dir ../public/pkg
	@touch $@

# Elm - only rebuilds if Elm source changes
public/elm.js: src/Main.elm src/Ports.elm
	elm make src/Main.elm --output=public/elm.js

# Favicon - only rebuilds if logo source changes
public/favicon.ico: icon/logo.typ
	cd icon && typst compile -f svg logo.typ && convert logo.svg -define icon:auto-resize=16,32,48,64,256 logo.ico && cp logo.ico ../public/favicon.ico

# Development server (uses fast WASM build)
dev: public/pkg/typst_math_svg_bg.wasm.dev public/elm.js public/favicon.ico
	bunx serve public -p 8000

# Deploy to gh-pages branch (always rebuilds optimized WASM)
deploy: public/elm.js public/favicon.ico
	cd wasm && wasm-pack build --target web --out-dir ../public/pkg
	@tmp=$$(mktemp -d) && \
	git clone --branch gh-pages --single-branch "$$(git remote get-url origin)" "$$tmp" && \
	rm -rf "$$tmp"/* && \
	cp -r public/. "$$tmp"/ && \
	cd "$$tmp" && git add -Af && git commit -S -m "Deploy" && git push && \
	rm -rf "$$tmp"

# Clean build artifacts
clean:
	rm -rf public/pkg public/pkg/typst_math_svg_bg.wasm.dev
	rm -f public/elm.js public/favicon.ico
	rm -rf wasm/target wasm/pkg result


