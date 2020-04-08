with builtins;
final: super: {
  bspwm = super.bspwm.overrideAttrs ({ patches ? [ ], ... }: {
    patches = patches ++ [
      # Fixes windows not getting resized properly when ignoring fullscreen events
      ./538d6197532fcf8547548b68dac6b511de57232e.diff
      # Forces pseudo-tiled nodes to occupy all space in monocle mode
      ./b860de08859c9f87b85c22a7415a8eae7df8690e.diff
      # Forces floating nodes to occupy all space in monocle mode
      ./66f608839e15bf917b0214a3f2fa5acd06dd5264.diff
    ];
  });
}
