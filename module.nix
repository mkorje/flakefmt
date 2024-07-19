{
  pkgs,
  lib,
  formatters,
  ...
}:
let
  package =
    self:
    let
      formattersPkgs = map (x: self.${x}) formatters;
      pkg = self.symlinkJoin {
        name = "treefmt";
        paths = [ self.treefmt2 ];
        buildInputs = [ self.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/treefmt \
            --add-flags "--tree-root-file=flake.nix" \
            --prefix PATH : ${self.lib.makeBinPath formattersPkgs}
        '';
      };
    in
    self.writeShellScriptBin "flakefmt" ''
      ${pkg}/bin/treefmt "$@"
    '';
in
{
  options = {
    package = lib.mkOption { };
    overlay = lib.mkOption { };
    check = lib.mkOption { };
  };

  config = {
    package = package pkgs;
    overlay = final: prev: { flakefmt = package final; };
    check =
      self:
      pkgs.runCommand "flakefmt-check"
        {
          buildInputs = [
            pkgs.git
            pkgs.diff-so-fancy
            (package pkgs)
          ];
        }
        ''
          set -e
          DIR=$(mktemp --directory)
          cp --recursive ${self}/. $DIR
          chmod -R a+w $DIR
          export HOME=$(mktemp --directory)
          cat > $HOME/.gitconfig <<EOF
          [user]
            name = Nix
            email = nix@localhost
          [init]
            defaultBranch = main
          EOF
          cd $DIR
          git init --quiet
          git add .
          git commit -m init --quiet
          export LANG=${if pkgs.stdenv.isDarwin then "en_US.UTF-8" else "C.UTF-8"}
          export LC_ALL=${if pkgs.stdenv.isDarwin then "en_US.UTF-8" else "C.UTF-8"}
          flakefmt --version
          flakefmt --no-cache
          git --no-pager diff --exit-code | diff-so-fancy
          touch $out
        '';
  };
}
