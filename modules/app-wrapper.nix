{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.app-wrapper;
  wrapApp = pkgs.callPackage ../pkgs/wrap-app.nix {};

  normalizeApplication = app:
    if lib.isDerivation app
    then {
      package = app;
      name = null;
      binary = null;
    }
    else app;

  applications = builtins.map normalizeApplication cfg.applications;

  mkWrapped = app:
    wrapApp (
      {pkg = app.package;}
      // lib.optionalAttrs (app.name != null) {inherit (app) name;}
      // lib.optionalAttrs (app.binary != null) {inherit (app) binary;}
    );
in {
  options.programs.app-wrapper = {
    enable = lib.mkEnableOption "wrapping selected packages into macOS .app bundles";

    applications = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.package (lib.types.submodule (_: {
        options = {
          package = lib.mkOption {
            type = lib.types.package;
            description = "Package that provides the binary to wrap.";
          };

          name = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Override display name for the generated app.";
          };

          binary = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Override the main binary name if the default does not work.";
          };
        };
      })));
      default = [];
      description = ''
        Packages to expose as standalone macOS applications.
        Items can be either derivations (for simple cases) or attribute sets for explicit control.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "programs.app-wrapper currently only supports macOS targets.";
      }
    ];

    home.packages = builtins.map mkWrapped applications;
  };
}
