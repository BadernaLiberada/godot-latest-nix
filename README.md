# godot-latest-nix
Latest Godot version for nixos wayland (Current 4.7 Beta 1).
Command is > godotlatest

add to your flake:

inputs = {
  godotlatest.url = "github:BadernaLiberada/godot-latest-nix";
}

outputs = { self, nixpkgs, godotlatest,  ... }

environment.systemPackages = [
  godotlatest.packages.x86_64-linux.default
];}
