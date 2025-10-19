# app_wrapper

Wrap any Nix package as a macOS `.app` bundle via a dedicated flake and Home Manager module,
so the resulting apps appear in `~/Applications`.

## Features

- Home Manager module `programs.app-wrapper` builds `.app` bundles by simply listing the packages you want.
- Override the app name, binary, launch arguments, environment variables, icon, and bundle identifier per application.
- Provides a reusable `wrapAppFor` helper and overlay for other flakes or derivations.

> ⚠️ Currently supported on macOS (Darwin) only.

## Usage

### 1. Reference the flake

```nix
{
  description = "Example home configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";

    app-wrapper = {
      url = "github:jasonxue1/app-wrapper";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    app-wrapper,
    ...
  }: let
    system = "aarch64-darwin";
    pkgs = import nixpkgs {inherit system;};
  in {
    homeConfigurations."my-user" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        app-wrapper.homeManagerModules.app-wrapper
        {
          programs.app-wrapper = {
            enable = true;
            applications = [
              pkgs.zathura
              {
                package = pkgs.kitty;
                name = "Kitty";
                args = ["--single-instance"];
                env = {LANG = "en_US.UTF-8";};
              }
            ];
          };
        }
      ];
    };
  };
}
```

### 2. Optional: customize Info.plist or icon

```nix
{
  programs.app-wrapper.applications = [
    {
      package = pkgs.neovide;
      name = "Neovide";
      icon = ./res/neovide.icns;
      bundleId = "com.example.neovide";
      infoPlistExtra = {
        LSUIElement = true;
      };
    }
  ];
}
```

### 3. Use the helper directly in other flakes

```nix
let
  wrapApp = app-wrapper.lib.wrapAppFor pkgs;
in {
  packages.zathuraApp = wrapApp {
    pkg = pkgs.zathura;
    name = "Zathura";
  };
}
```

The resulting derivation contains the `.app` directory structure and can be installed directly or referenced from Home Manager.
