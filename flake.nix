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

    stylix.url = "github:danth/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      spicetify-nix,
      stylix,
      ...
    }@inputs:
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
            inputs.stylix.nixosModules.stylix
            {
              nixpkgs.config.allowUnfree = true;
              nixpkgs.overlays = [ (import ./pkgs) ];

              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = mkSpecialArgs linuxSystem;
                users.${user} = {
                  imports = [
                    ./home/linux
                    ./hosts/nixos-desktop/home.nix
                  ];
                };
                sharedModules = [
                  inputs.stylix.homeModules.stylix
                ];
                backupFileExtension = "backup";
              };
            }
          ];
        };

        nixos-laptop = nixpkgs.lib.nixosSystem {
          system = linuxSystem;
          specialArgs = mkSpecialArgs linuxSystem;
          modules = [
            ./hosts/nixos-laptop
            home-manager.nixosModules.home-manager
            inputs.stylix.nixosModules.stylix
            {
              nixpkgs.config.allowUnfree = true;
              nixpkgs.overlays = [ (import ./pkgs) ];

              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = mkSpecialArgs linuxSystem;
                users.${user} = {
                  imports = [
                    ./home/linux
                    ./hosts/nixos-laptop/home.nix
                  ];
                };
                sharedModules = [
                  inputs.stylix.homeModules.stylix
                ];
                backupFileExtension = "backup";
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
              # Allow unfree packages
              nixpkgs.config.allowUnfree = true;
              nixpkgs.overlays = [ (import ./pkgs) ];

              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = mkSpecialArgs darwinSystem;
                users.${user} = {
                  imports = [
                    ./home/darwin
                  ];
                };
                sharedModules = [ inputs.stylix.homeModules.stylix ];
              };
            }
          ];
        };
      };
    };
}
