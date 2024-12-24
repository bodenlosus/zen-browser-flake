{
  description = "Zen Browser";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable"; };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      version = "%VERSION%"; # 
      downloadUrl = {
        "x86_64-linux" = {
          url =
            "%x86_64_URL%";
          sha256 =
            "sha256:%x86_64_SHA256%";
        };
        "aarch64-linux" = {
          url =
            "%aarch64_URL%";
          sha256 =
            "sha256:%aarch64_SHA256%";
        };
      };

      pkgs = import nixpkgs { inherit system; };

      runtimeLibs = with pkgs;
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

      mkZen = { variant }:
        let downloadData = downloadUrl."${variant}";
        in pkgs.stdenv.mkDerivation {
          inherit version;
          pname = "zen-browser";

          src = builtins.fetchTarball {
            url = downloadData.url;
            sha256 = downloadData.sha256;
          };

          desktopSrc = ./.;

          phases = [ "installPhase" "fixupPhase" ];

          nativeBuildInputs =
            [ pkgs.makeWrapper pkgs.copyDesktopItems pkgs.wrapGAppsHook ];

          installPhase =
            "  mkdir -p $out/bin && cp -r $src/* $out/bin\n  install -D $desktopSrc/zen.desktop $out/share/applications/zen.desktop\n  install -D $src/browser/chrome/icons/default/default128.png $out/share/icons/hicolor/128x128/apps/zen.png\n";

          fixupPhase = ''
            		  chmod 755 $out/bin/*
            		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/zen
            		  wrapProgram $out/bin/zen --set LD_LIBRARY_PATH "${
                  pkgs.lib.makeLibraryPath runtimeLibs
                }" \
                                --set MOZ_LEGACY_PROFILES 1 --set MOZ_ALLOW_DOWNGRADE 1 --set MOZ_APP_LAUNCHER zen --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
            		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/zen-bin
            		  wrapProgram $out/bin/zen-bin --set LD_LIBRARY_PATH "${
                  pkgs.lib.makeLibraryPath runtimeLibs
                }" \
                                --set MOZ_LEGACY_PROFILES 1 --set MOZ_ALLOW_DOWNGRADE 1 --set MOZ_APP_LAUNCHER zen --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
            		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/glxtest
            		  wrapProgram $out/bin/glxtest --set LD_LIBRARY_PATH "${
                  pkgs.lib.makeLibraryPath runtimeLibs
                }"
            		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/updater
            		  wrapProgram $out/bin/updater --set LD_LIBRARY_PATH "${
                  pkgs.lib.makeLibraryPath runtimeLibs
                }"
            		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/vaapitest
            		  wrapProgram $out/bin/vaapitest --set LD_LIBRARY_PATH "${
                  pkgs.lib.makeLibraryPath runtimeLibs
                }"
            		'';

          meta.mainProgram = "zen";
        };
    in {
      packages."${system}" = {
        x86_64-linux = mkZen { variant = "x86_64-linux"; };
        aarch64-linux = mkZen { variant = "aarch64-linux"; };
        default = self.packages."${system}".x86_64-linux;
      };
    };
}