{
  description = "Latest upstream Godot beta for NixOS, Wayland-first";

  inputs = {
    # Your system flake can override this with:
    #
    # godotlatest.inputs.nixpkgs.follows = "nixpkgs-unstable";
    #
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      mkGodot = system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

          version = "4.7-beta1";
          godotBinary = "Godot_v4.7-beta1_linux.x86_64";

          godotLibs = with pkgs; [
            # Fonts / text
            fontconfig
            freetype
            graphite2
            harfbuzz
            icu

            # Wayland
            wayland
            libxkbcommon
            libdecor

            # X11 fallback libs.
            # Even on Wayland, Godot/nixpkgs still keeps these around because
            # parts of linuxbsd support may expect them.
            xorg.libX11
            xorg.libXcursor
            xorg.libXext
            xorg.libXfixes
            xorg.libXi
            xorg.libXinerama
            xorg.libXrandr
            xorg.libXrender
            xorg.libxcb

            # Graphics / EGL / Vulkan
            libGL
            mesa
            vulkan-loader

            # Audio
            alsa-lib
            libpulseaudio
            pipewire

            # System integration
            dbus
            udev
            glib
            zlib
          ];

          runtimeLibraryPath = pkgs.lib.makeLibraryPath godotLibs;

          godot = pkgs.stdenv.mkDerivation {
            pname = "godotlatest";
            inherit version;

            src = pkgs.fetchzip {
              url = "https://godot-releases.nbg1.your-objectstorage.com/${version}/Godot_v${version}_linux.x86_64.zip";

              # First build will fail and print the real hash.
              # Replace this with the printed sha256.
              hash = "sha256-4CmcTpSlKxN28R91EDXBAkkTXXmrF3fWUUc8kE1QxPw=";

              stripRoot = false;
            };

            nativeBuildInputs = with pkgs; [
              autoPatchelfHook
              makeWrapper
            ];

            buildInputs = godotLibs;

            installPhase = ''
              runHook preInstall

              mkdir -p "$out/bin"
              cp "$src/${godotBinary}" "$out/bin/godotlatest"
              chmod +x "$out/bin/godotlatest"

              wrapProgram "$out/bin/godotlatest" \
                --prefix LD_LIBRARY_PATH : "${runtimeLibraryPath}:/run/opengl-driver/lib" \
                --add-flags "--display-driver wayland" \
                --add-flags "--rendering-driver vulkan"

              runHook postInstall
            '';

            meta = {
              description = "Upstream Godot beta binary wrapped for NixOS";
              homepage = "https://godotengine.org";
              license = pkgs.lib.licenses.mit;
              platforms = supportedSystems;
              mainProgram = "godotlatest";
            };
          };
        in
          godot;
    in {
      packages = forAllSystems (system: {
        default = mkGodot system;
        godotlatest = mkGodot system;
      });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/godotlatest";
        };

        godotlatest = {
          type = "app";
          program = "${self.packages.${system}.godotlatest}/bin/godotlatest";
        };
      });

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in {
          default = pkgs.mkShell {
            packages = [
              self.packages.${system}.default
            ];
          };
        }
      );
    };
}
