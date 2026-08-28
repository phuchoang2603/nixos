{
  description = "NixOS and macOS configuration for felix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      ...
    }@inputs:
    let
      user = "felix";

      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ inputs.neovim-nightly-overlay.overlays.default ];
        };

      mkHomeConfig =
        {
          modules,
          stylix ? false,
        }:
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            extraSpecialArgs = { inherit inputs user; };
            sharedModules = nixpkgs.lib.optionals stylix [ inputs.stylix.homeModules.stylix ];
            users.${user}.imports = modules;
          };
        };

      mkNixos =
        {
          system,
          host,
          homeModules ? [ ],
          stylix ? false,
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs user; };
          modules = [
            { nixpkgs.pkgs = mkPkgs system; }
            host
            home-manager.nixosModules.home-manager
          ]
          ++ nixpkgs.lib.optionals stylix [ inputs.stylix.nixosModules.stylix ]
          ++ [
            (mkHomeConfig {
              modules = homeModules;
              inherit stylix;
            })
          ];
        };

      mkDarwin =
        {
          system,
          host,
          homeModules ? [ ],
          stylix ? true,
        }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit inputs user; };
          modules = [
            { nixpkgs.pkgs = mkPkgs system; }
            host
            home-manager.darwinModules.home-manager
            (mkHomeConfig {
              modules = homeModules;
              inherit stylix;
            })
          ];
        };
    in
    {
      nixosConfigurations = {
        nixos-desktop = mkNixos {
          system = "x86_64-linux";
          host = ./hosts/nixos-desktop;
          homeModules = [
            ./home/linux
            ./hosts/nixos-desktop/home.nix
          ];
          stylix = true;
        };

        nixos-server = mkNixos {
          system = "x86_64-linux";
          host = ./hosts/nixos-server;
          homeModules = [ ./home/server ];
          stylix = false;
        };
      };

      darwinConfigurations = {
        macbook = mkDarwin {
          system = "aarch64-darwin";
          host = ./hosts/macbook;
          homeModules = [ ./home/darwin ];
          stylix = true;
        };
      };
    };
}
