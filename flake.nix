{
  description = "NixOS and macOS configuration for felix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, spicetify-nix, ... }@inputs:
    let
      # User configuration
      user = "felix";

      # System configurations
      linuxSystem = "x86_64-linux";
      darwinSystem = "aarch64-darwin";

      # Shared specialArgs for all configurations
      mkSpecialArgs = system: {
        inherit inputs user;
      };
    in
    {
      # NixOS configurations
      nixosConfigurations = {
        nixos-desktop = nixpkgs.lib.nixosSystem {
          system = linuxSystem;
          specialArgs = mkSpecialArgs linuxSystem;
          modules = [
            ./hosts/nixos-desktop
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = mkSpecialArgs linuxSystem;
                users.${user} = import ./modules/home;
              };
            }
          ];
        };
      };

      # macOS configurations (nix-darwin)
      darwinConfigurations = {
        macbook = nix-darwin.lib.darwinSystem {
          system = darwinSystem;
          specialArgs = mkSpecialArgs darwinSystem;
          modules = [
            ./hosts/macbook
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = mkSpecialArgs darwinSystem;
                users.${user} = import ./modules/home;
              };
            }
          ];
        };
      };
    };
}
