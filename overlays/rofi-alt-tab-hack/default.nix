final: super: {
  rofi-unwrapped = super.rofi-unwrapped.overrideAttrs ({ patches ? [], ... }: {
    patches = patches ++ [ ./alt-tab-hack.diff ];
  });
}
