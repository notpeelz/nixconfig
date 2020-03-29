with builtins;
final: super: {
  bspwm = super.bspwm.overrideAttrs ({ patches ? [ ], ... }: {
    patches = patches ++ map super.fetchpatch [
      # Fixes windows not getting resized properly when ignoring fullscreen events
      { url = "https://github.com/louistakepillz/bspwm/commit/538d6197532fcf8547548b68dac6b511de57232e.diff";
        sha256 = "09qkk0w21wdqg95mrvj7mg09gf2bxz1rh3rc51dzyj2wg4xq0q26";
      }
      }
    ];
  });
}
