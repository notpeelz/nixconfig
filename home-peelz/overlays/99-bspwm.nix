with builtins;
final: super: {
  bspwm = super.bspwm.overrideAttrs ({ patches ? [ ], ... }: {
    patches = patches ++ map super.fetchpatch [
      # Fixes windows not getting resized properly when ignoring fullscreen events
      { url = "https://github.com/louistakepillz/bspwm/commit/538d6197532fcf8547548b68dac6b511de57232e.diff";
        sha256 = "09qkk0w21wdqg95mrvj7mg09gf2bxz1rh3rc51dzyj2wg4xq0q26";
      }
      # Forces pseudo-tiled nodes to occupy all space in monocle mode
      { url = "https://github.com/louistakepillz/bspwm/commit/b860de08859c9f87b85c22a7415a8eae7df8690e.diff";
        sha256 = "1adz7wgg6p3p9hlcs17fn2c7sa3zhbagmq0yq63livrjdbbpy7ki";
      }
      # Forces floating nodes to occupy all space in monocle mode
      { url = "https://github.com/louistakepillz/bspwm/commit/66f608839e15bf917b0214a3f2fa5acd06dd5264.diff";
        sha256 = "0pnz9j2gwyfhjdnald7xkxqki6lg8ryi88iq8h4ngrhq9vbv70hc";
      }
    ];
  });
}
