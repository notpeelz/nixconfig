# Improves zsh SIGWINCH handling
# Source: https://github.com/romkatv/powerlevel10k#zsh-patch

with builtins;
final: super: {
  zsh = super.zsh.overrideAttrs ({ patches ? [ ], ... }: {
    patches = patches ++ map super.fetchpatch [
      {
        url = "https://github.com/louistakepillz/zsh/commit/f016535cb6fd466207d16770d3dcedfafc1799e9.diff";
        sha256 = "189fhfcjk1l2zhpxw5r754nxpfhxl2b0ixwhy2xk91fmsbakz0i9";
      }
      {
        url = "https://github.com/louistakepillz/zsh/commit/f5bf5a014675d3b8ff5c1da9f4de42363f0ba2aa.diff";
        sha256 = "0nr2dw3pwqz0x906d24dhqvw9wmvy7c72rgws4rmg327qk1abvfc";
      }
    ];
  });
}
