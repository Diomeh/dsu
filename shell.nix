{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    bacon # Background rust code checker
    shellcheck # Shell script linter
    shunit2 # Shell script unit testing framework
    shfmt # Shell script formatter
  ];
}
