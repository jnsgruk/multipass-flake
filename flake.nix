{
  description = "multipass flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }: let
    inherit (self) outputs;
  in
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in rec {
        packages = {
          multipass = pkgs.libsForQt5.callPackage ./multipass.nix {inherit outputs;};
          default = packages.multipass;
        };

        apps.default = {
          type = "app";
          program = "${packages.multipass}/bin/multipass";
        };
      }
    );
}
