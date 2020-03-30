# Change nautilus' desktop name from "Files" to "Nautilus"

final: super: {
  gnome3 = super.gnome3 // {
    nautilus = super.gnome3.nautilus.overrideAttrs ({ postFixup ? "", ... }: {
      postFixup = postFixup + ''
        sed -i '
          /^Name\[.*\].*=.*/d
          s/Name=.*/Name=Nautilus/
        ' $out/share/applications/org.gnome.Nautilus.desktop
      '';
    });
  };
}
