# Fix neovim's desktop name showing up as "WrappedNeovim"

with builtins;
final: super: {
  neovim = super.neovim.overrideAttrs ({ buildCommand, ... }: {
    buildCommand =
      replaceStrings [ "Name=WrappedNeovim" ] [ "Name=Neovim" ]
      buildCommand;
  });
}
