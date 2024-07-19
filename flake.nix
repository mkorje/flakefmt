{
  description = "flakefmt, a simple wrapper around treefmt for nix flakes";

  outputs =
    { self }:
    {
      lib.eval =
        formatters:
        (
          nixpkgs:
          (nixpkgs.lib.evalModules {
            modules = [ ./module.nix ];
            specialArgs = {
              pkgs = nixpkgs;
              lib = nixpkgs.lib;
              inherit formatters;
            };
          }).config
        );
    };
}
