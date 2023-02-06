{
  description = "nixos multipass flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        inherit (self) outputs;
        pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        packages = {
          multipass = pkgs.libsForQt5.callPackage ./modules/multipass/package.nix { };
          default = packages.multipass;
        };

        nixosModule = import ./modules/multipass;
        nixosModules.default = self.nixosModule.${system};
      }
    );
}
