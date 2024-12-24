{
  description = "Zen Browser";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable"; };

  outputs = { self, nixpkgs }: 
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];

      downloadUrl = {
        "x86_64-linux" = {
          url = "%x86_64_URL%";
          sha256 = "sha256:%x86_64_SHA256%";
        };
        "aarch64-linux" = {
          url = "%aarch64_URL%";
          sha256 = "sha256:%aarch64_SHA256%";
        };
      };

      runtimeLibs = pkgs: with pkgs;
        [
          libGL
          libGLU
          libevent
          libffi
          libjpeg
          libpng
          libstartup_notification
          libvpx
          libwebp
          stdenv.cc.cc
          fontconfig
          libxkbcommon
          zlib
          freetype
          gtk3
          libxml2
          dbus
          xcb-util-cursor
          alsa-lib
          libpulseaudio
          pango
          atk
          cairo
          gdk-pixbuf
          glib
          udev
          libva
          mesa
          libnotify
          cups
          pciutils
          ffmpeg
          libglvnd
          pipewire
        ] ++ (with pkgs.xorg; [
          libxcb
          libX11
          libXcursor
          libXrandr
          libXi
          libXext
          libXcomposite
          libXdamage
          libXfixes
          libXScrnSaver
        ]);

      mkZen = { pkgs, system, variant }:
        let downloadData = downloadUrl.${variant};
        in pkgs.stdenv.mkDerivation {
          pname = "zen-browser";
          version = "%VERSION%";

          src = pkgs.fetchzip {
            url = downloadData.url;
            sha256 = downloadData.sha256;
          };

          desktopSrc = ./.;

          phases = [ "installPhase" "fixupPhase" ];

          nativeBuildInputs = [
            pkgs.makeWrapper
            pkgs.copyDesktopItems
            pkgs.wrapGAppsHook
          ];

          installPhase = ''
            mkdir -p $out/bin
            cp -r $src/* $out/bin
            install -D $desktopSrc/zen.desktop $out/share/applications/zen.desktop
            install -D $src/browser/chrome/icons/default/default128.png $out/share/icons/hicolor/128x128/apps/zen.png
          '';

          fixupPhase = ''
            chmod 755 $out/bin/*
            for binary in zen zen-bin glxtest updater vaapitest; do
              if [ -e $out/bin/$binary ]; then
                patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/$binary
                wrapProgram $out/bin/$binary \
                  --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath (runtimeLibs pkgs)}" \
                  --set MOZ_LEGACY_PROFILES 1 \
                  --set MOZ_ALLOW_DOWNGRADE 1 \
                  --set MOZ_APP_LAUNCHER zen \
                  --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
              fi
            done
          '';

          meta = with pkgs.lib; {
            description = "Flake for the Zen Browser";
            platforms = supportedSystems;
            maintainers = [ "bodenlosus" ];
            mainProgram = "zen";
          };
        };
    in
    {
      packages = builtins.listToAttrs (map (system: {
        name = system;
        value = mkZen {
          pkgs = import nixpkgs { inherit system; };
          system = system;
          variant = system;
        };
      }) supportedSystems);

      defaultPackage.x86_64-linux = self.packages.x86_64-linux;
      defaultPackage.aarch64-linux = self.packages.aarch64-linux;
    };
}
