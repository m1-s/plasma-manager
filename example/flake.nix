{
  description = "Plasma Manager Example";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    plasma-manager.url = "github:pjones/plasma-manager";
    plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
    plasma-manager.inputs.home-manager.follows = "home-manager";
  };

  outputs = { self, nixpkgs, home-manager, plasma-manager }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      username = "jdoe";
    in
    {
      # Standalone Home Manager Setup:
      homeConfigurations.${username} =
        home-manager.lib.homeManagerConfiguration {
          inherit system;
          # Ensure Plasma Manager is available:
          extraModules = [
            plasma-manager.homeManagerModules.plasma-manager
          ];

          # Specify the path to your home configuration here:
          configuration = import ./home.nix;

          homeDirectory = "/home/${username}";
          };

      packages.${system}.demo = (nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          (import ./demo.nix {
            home-manager-module = home-manager.nixosModules.home-manager;
            plasma-module = plasma-manager.homeManagerModules.plasma-manager;
          })
        ];
      }).config.system.build.vm;

      # A shell where Home Manager can be used:
      devShells.${system}.default = pkgs.mkShell {
        nativeBuildInputs = [
          pkgs.home-manager
        ];
      };
    };
}
