# Delete the xterm desktop file (prevents it from showing up in rofi)

with builtins;
final: super: {
  xterm = super.xterm.overrideAttrs ({ postInstall ? "", ... }: {
    postInstall = postInstall + ''
      rm $out/share/applications/xterm.desktop
    '';
  });
}
