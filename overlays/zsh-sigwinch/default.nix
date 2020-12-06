# Improves zsh SIGWINCH handling
# Source: https://github.com/romkatv/powerlevel10k#zsh-patch

with builtins;
final: super: {
  zsh = super.zsh.overrideAttrs ({ patches ? [ ], ... }: {
    patches = patches ++ [
      # Breaks with zsh 5.8
      # TODO: rebase?
      # ./f016535cb6fd466207d16770d3dcedfafc1799e9.diff
      # ./f5bf5a014675d3b8ff5c1da9f4de42363f0ba2aa.diff
    ];
  });
}
