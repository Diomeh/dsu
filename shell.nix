{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    bacon # Background rust code checker
    rustfmt # Rust code checker
    clippy # Bunch of lints to catch common mistakes and improve your Rust code
    shellcheck # Shell script linter
    shunit2 # Shell script unit testing framework
    shfmt # Shell script formatter
  ];
}
