with builtins;
final: super: {
  bspwm = super.bspwm.overrideAttrs ({ patches ? [ ], ... }: {
    patches = patches ++ map super.fetchpatch [
      # Fixes windows not getting resized properly when ignoring fullscreen events
      { url = "https://github.com/louistakepillz/bspwm/commit/538d6197532fcf8547548b68dac6b511de57232e.patch";
        sha256 = "072q2pg31vn52hb3b4q9v0m7cqbf7ibhy8y6rpmp3pcmd1ddmwzj";
      }
    ];
  });
}
