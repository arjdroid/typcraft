# typcraft

[typcraft](https://typcraft.nxtdroid.win) is a website to practice composing equations with the [typst](https://typst.app) typesetting system. It is pretty fun, if only for me.

Inspired by [texnique.xyz](https://texnique.xyz) which does the same for LaTeX. Your editing environment is locked to Math mode.

You can use it as a live `typst` code preview in your browser (even mobile). It uses the full typst compiler running in WebAssembly, and renders the resulting SVG.

I plan to add a 'playground' math mode, perhaps even expanding scope to a quick typst environment akin to running  `typst watch temp.typ` with your editor and viewer on your computer. (shipping the compiler as a wasm binary is the heaviest part)

> You are encouraged to read [ARCHITECTURE.md](./ARCHITECTURE.md) if you would like to know more about how it draws and checks formulae. Or, just read `src/Main.elm` it is really neat!

## Development

You need to have [nix](https://nixos.org/download/) on your system, it takes care of all the dependencies. (Optional: `direnv` and `nix-direnv` can make development even more convenient)

```bash
# Clone repository
git clone https://github.com/arjdroid/typcraft
cd typcraft

# Enter development environment
nix develop

# Preview changes using bun
make dev

# Push changes to github-pages
make deploy
```

## Todo
- [x] get `typst` running in the browser
- [x] get live preview working
- [x] get formula checking working
- [x] add more formulae (perpetual)
- [x] add links to guides
- [ ] pseudo randomisation of levels; avoid repeats
- [ ] level selector
- [ ] NNG4-style 'worlds', distinct difficulty levels, specific hints
- [ ] add preview / shadow mode
- [ ] add distinct playground mode
- [ ] improve smartphone experience (already beyond meagre expectations with FF on Android)

> Acknowledgement: The development of this project was assisted by the use of Claude Code
(Claude Opus 4.5, Anthropic)
