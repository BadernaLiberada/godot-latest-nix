{
  description = "Upstream Godot (Wayland-only) with godotlatest command";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      version = "4.7-beta1";
      godotBinary = "Godot_v4.7-beta1_linux.x86_64";

      godot = pkgs.stdenv.mkDerivation {
        pname = "godotlatest";
        inherit version;

        src = pkgs.fetchzip {
          url = "https://godot-releases.nbg1.your-objectstorage.com/${version}/Godot_v${version}_linux.x86_64.zip";
          hash = pkgs.lib.fakeHash; # replace after first run
          stripRoot = false;
        };

        nativeBuildInputs = with pkgs; [
          autoPatchelfHook
          makeWrapper
        ];

        buildInputs = with pkgs; [
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

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          cp $src/${godotBinary} $out/bin/godotlatest
          chmod +x $out/bin/godotlatest

          wrapProgram $out/bin/godotlatest \
            --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath buildInputs}" \
            --add-flags "--display-driver wayland"

          runHook postInstall
        '';
      };

    in {
      packages.${system}.godotlatest = godot;
      packages.${system}.default = godot;

      apps.${system}.godotlatest = {
        type = "app";
        program = "${godot}/bin/godotlatest";
      };

      apps.${system}.default = self.apps.${system}.godotlatest;

      devShells.${system}.default = pkgs.mkShell {
        packages = [ godot ];
      };
    };
}
