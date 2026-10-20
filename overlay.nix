final: prev:
let
  python3Packages = prev.python3Packages.overrideScope (
    self: super: {
      pyodata = self.callPackage ./pkgs/development/python-modules/pyodata { };
    }
  );
in
{
  inherit python3Packages;

  sapcli = final.callPackage ./pkgs/by-name/sa/sapcli/package.nix {
    inherit python3Packages;
  };
}
