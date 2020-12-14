with builtins;
final: super: with super.lib; {
  # TODO: name and version attributes aren't exposed through kdeApplications/default.nix
  # hopefully this can be fixed when PR#106923 makes it to stable
  # spectacle = super.spectacle.overrideAttrs ({ pname ? null, version ? null, patches ? [], ... }: let
  #   isItPatchedYet = patchedVersion: if versionAtLeast version patchedVersion
  #     then warn "${pname} has updated, some patches may no longer we required";
  #     else false;
  spectacle = super.spectacle.overrideAttrs ({ name, patches ? [], ... }: let
    version = head (reverseList (splitString "-" name));
    isItPatchedYet = patchedVersion: if versionAtLeast version patchedVersion
      then warn "spectacle has updated; some patches may no longer we required" true
      else false;
  in {
    patches = patches
      ++ (optionals (!(isItPatchedYet "20.11.80")) [
        (super.fetchpatch {
          name = "fix-output-param.patch";
          url = "https://github.com/KDE/spectacle/commit/7f88fcb4bb4085f39b7330212efacb19c2b5bcad.patch";
          sha256 = "1ll31kcdc3nn8dr7zz2i93jp0qvzbi2ysb2adp0qc2c89nibp0l1";
        })
      ]);
  });
}
