# flakefmt

A simple wrapper around treefmt, allowing you to use it in a nix flake.

You specify the formatter packages needed, and we provide a wrapper package
around treefmt with them in PATH. Then you can use this as the package for the
`formatter` flake output to format all the code in your project with
`nix fmt`. There is also a check provided to see if all the code in your
project has been properly formatted with `nix flake check`. Finally, there is
an overlay that adds the wrapper package to nixpkgs as `flakefmt`, which has
executable `flakefmt`.

Note that this tool uses the `treefmt.toml` configuration file (which should
be at the root of your project), it *does not* use a configuration in nix
(like the offical [treefmt-nix](https://github.com/numtide/treefmt-nix) does).

## Usage

First, add `flakefmt.url = "github:mkorje/flakefmt";` to the inputs of your
flake. Now you can create an 'instance' of flakefmt with a list of the
formatters needed (from nixpkgs), as specified in your `treefmt.toml` file.
Note that the command for the formatter may not always actually be the name of
the package in nixpkgs.

```nix
flakefmtEval = flakefmt.lib.eval [
  "taplo"
  "nixfmt-rfc-style"
  "black"
];
```

You can then use

- `(flakefmtEval pkgs).package` to get a derivation of the wrapper package
created (with executable `flakefmt`)

- `(flakefmtEval pkgs).overlay` to get an overlay which adds the wrapper
package created to nixpkgs as `flakefmt`

- `(flakefmtEval pkgs).check <dir>` to get a derivation which runs `flakefmt`
on the directory provided (this will usually be the flake itself, accessible
using the input `self`) and prints a diff.

## Example

An example of what a very basic flake using this might look like.

<details>

<summary>flake.nix</summary>

```nix
{
  description = "example flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    flakefmt.url = "github:mkorje/flakefmt";
  };

  outputs =
    {
      self,
      nixpkgs,
      flakefmt,
    }:
    let
      # list of systems
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      # flakefmt 'instance'
      flakefmtEval = flakefmt.lib.eval [
        "black"
        "nixfmt-rfc-style"
        "taplo"
      ];

      # function to create attribute sets for each system
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f (
            import nixpkgs {
              inherit system;
              # this adds the package `flakefmt` to nixpkgs
              overlays = [ (flakefmtEval nixpkgs).overlay ];
            }
          )
        );
    in
    {
      # used by `nix fmt`
      formatter = forAllSystems (pkgs: pkgs.flakefmt);
      # since we applied the overlay, we can use pkgs.flakefmt
      # otherwise, we can use the below to get the package
      formatter = forAllSystems (pkgs: (flakefmtEval pkgs).package);

      # used by `nix flake check`
      checks = forAllSystems (pkgs: {
        # we want to format our whole project (the flake/git repo), so we use
        # self to reference the flake itself
        formatting = (flakefmtEval pkgs).check self;
      });
    };
}
```

</details>
