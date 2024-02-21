{
  description = "Manage KDE Plasma with Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      defaultSystems = [
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      eachSystem = systems: f:
        let
          # Merge together the outputs for all systems. a
          op = attrs: system:
            let
              ret = f system;
              op = attrs: key: attrs // {
                ${key} = (attrs.${key} or { })
                  // { ${system} = ret.${key}; };
              };
            in
            builtins.foldl' op attrs (builtins.attrNames ret);
        in
        builtins.foldl' op { } systems;
    in
    eachSystem defaultSystems
      (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          packages = {
            default = self.packages.${system}.rc2nix;

            rc2nix = pkgs.writeShellApplication {
              name = "rc2nix";
              runtimeInputs = with pkgs; [ ruby ];
              text = ''ruby ${script/rc2nix.rb} "$@"'';
            };
          };

          apps = {
            default = self.apps.${system}.rc2nix;

            rc2nix = {
              type = "app";
              program = "${self.packages.${system}.rc2nix}/bin/rc2nix";
            };
          };

          checks = {
            basic = pkgs.callPackage ./test/basic.nix {
              home-manager-module = home-manager.nixosModules.home-manager;
              plasma-module = self.homeManagerModules.plasma-manager;
            };
          };

          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              ruby
              ruby.devdoc
            ];
          };
        }) // {
      homeManagerModules = {
        plasma-manager = { ... }: {
          imports = [ ./modules ];
        };
        default = self.homeManagerModules.plasma-manager;
      };
    };
}
