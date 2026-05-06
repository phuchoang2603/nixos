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

      mkHomeConfig = extraModules: {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          extraSpecialArgs = { inherit inputs user; };
          sharedModules = [ inputs.stylix.homeModules.stylix ];
          users.${user} = {
            imports = extraModules;
          };
        };
      };
    in
    {
      nixosConfigurations = {
        nixos-desktop =
          let
            system = "x86_64-linux";
          in
          nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = { inherit inputs user; };
            modules = [
              { nixpkgs.pkgs = mkPkgs system; }
              ./hosts/nixos-desktop
              home-manager.nixosModules.home-manager
              inputs.stylix.nixosModules.stylix
              (mkHomeConfig [
                ./home/linux
                ./hosts/nixos-desktop/home.nix
              ])
            ];
          };

        nixos-laptop =
          let
            system = "x86_64-linux";
          in
          nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = { inherit inputs user; };
            modules = [
              { nixpkgs.pkgs = mkPkgs system; }
              ./hosts/nixos-laptop
              home-manager.nixosModules.home-manager
              inputs.stylix.nixosModules.stylix
              (mkHomeConfig [
                ./home/linux
                ./hosts/nixos-laptop/home.nix
              ])
            ];
          };
      };

      darwinConfigurations.macbook =
        let
          system = "aarch64-darwin";
        in
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit inputs user; };
          modules = [
            { nixpkgs.pkgs = mkPkgs system; }
            ./hosts/macbook
            home-manager.darwinModules.home-manager
            (mkHomeConfig [ ./home/darwin ])
          ];
        };
    };
}
