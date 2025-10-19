{
  description = "Home Manager module for turning Nix packages into macOS .app bundles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = args: let
    inherit (args) nixpkgs flake-utils;
  in
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [];
          config.allowUnfree = false;
        };

        wrapApp = pkgs.callPackage ./pkgs/wrap-app.nix {};
      in {
        packages = {
          default = wrapApp {
            pkg = pkgs.hello;
            name = "HelloApp";
          };
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nixpkgs-fmt
          ];
        };
      }
    )
    // {
      lib = {
        wrapAppFor = pkgs: pkgs.callPackage ./pkgs/wrap-app.nix {};
      };

      homeManagerModules = {
        default = import ./modules/app-wrapper.nix;
        app-wrapper = import ./modules/app-wrapper.nix;
      };

      overlays.default = final: _: {
        wrapApp = final.callPackage ./pkgs/wrap-app.nix {};
      };

      hmModules.app-wrapper = import ./modules/app-wrapper.nix;

      nixosModules = {};
    };
}
