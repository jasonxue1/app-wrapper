{
  lib,
  stdenvNoCC,
  runtimeShell,
}: {
  pkg,
  name ? null,
  binary ? null,
}: let
  inherit (lib.strings) sanitizeDerivationName;
  meta = pkg.meta or {};

  displayName =
    if name != null
    then name
    else pkg.pname or (meta.name or (pkg.name or "WrappedApp"));

  sanitizedName = sanitizeDerivationName displayName;

  defaultBinary = meta.mainProgram or sanitizedName;

  binaryName =
    if binary != null
    then binary
    else defaultBinary;

  exePath = "${lib.getBin pkg}/bin/${binaryName}";

  bundleIdentifier = "org.nix.appwrapper.${sanitizedName}";

  infoPlist = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleName</key>
      <string>${displayName}</string>
      <key>CFBundleExecutable</key>
      <string>${sanitizedName}</string>
      <key>CFBundleIdentifier</key>
      <string>${bundleIdentifier}</string>
      <key>CFBundleInfoDictionaryVersion</key>
      <string>6.0</string>
      <key>CFBundlePackageType</key>
      <string>APPL</string>
    </dict>
    </plist>
  '';
in
  stdenvNoCC.mkDerivation {
    pname = sanitizedName;
    version = pkg.version or "1.0";

    dontUnpack = true;

    buildCommand = ''
            app="$out/Applications/${displayName}.app"
            mkdir -p "$app/Contents/MacOS"
            cat <<'EOF' > "$app/Contents/MacOS/${sanitizedName}"
      #!${runtimeShell}
      set -euo pipefail
      args=()
      for arg in "$@"; do
        case "$arg" in
          -psn_*) ;;
          *) args+=("$arg") ;;
        esac
      done

      exec ${exePath} "''${args[@]}"
      EOF
            chmod +x "$app/Contents/MacOS/${sanitizedName}"

            mkdir -p "$app/Contents/Resources"
            cat <<'EOF' > "$app/Contents/Info.plist"
      ${infoPlist}
      EOF
    '';

    meta = {
      description = "Minimal macOS .app wrapper for ${displayName}";
      platforms = lib.platforms.darwin;
    };
  }
