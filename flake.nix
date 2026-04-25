{
  description = "Latest upstream Godot for NixOS, Wayland-only";

  inputs = {
    # This will be overridden by your system flake using:
    # godotlatest.inputs.nixpkgs.follows = "nixpkgs-unstable";
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
          pkgs = import nixpkgs { inherit system; };

          version = "4.7-beta1";
          godotBinary = "Godot_v4.7-beta1_linux.x86_64";

          godotLibs = with pkgs; [
            fontconfig
            freetype

            wayland
            libxkbcommon
            libdecor

            mesa
            vulkan-loader

            alsa-lib
            pipewire
            pulseaudio

            dbus
            udev
            zlib
            glib
          ];
        in
          pkgs.stdenv.mkDerivation {
            pname = "godotlatest";
            inherit version;

            src = pkgs.fetchzip {
              url = "https://godot-releases.nbg1.your-objectstorage.com/${version}/Godot_v${version}_linux.x86_64.zip";

              # First build will fail and print the real hash.
              # Replace this with the printed sha256.
              hash = pkgs.lib.fakeHash;

              stripRoot = false;
            };

            nativeBuildInputs = with pkgs; [
              autoPatchelfHook
              makeWrapper
            ];

            buildInputs = godotLibs;

            installPhase = ''
              runHook preInstall

              mkdir -p $out/bin
              cp $src/${godotBinary} $out/bin/godotlatest
              chmod +x $out/bin/godotlatest

              wrapProgram $out/bin/godotlatest \
                --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath godotLibs}" \
                --add-flags "--display-driver wayland"

              runHook postInstall
            '';
          };
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
          pkgs = import nixpkgs { inherit system; };
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
