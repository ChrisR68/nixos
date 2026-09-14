{
  description = "NixOS Konfiguration fuer Multi-Host (nixos & Gen2)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { self, nixpkgs, home-manager, plasma-manager, ... }@inputs:
  let
    system = "x86_64-linux";
    
    # Gemeinsame Module fuer beide Systeme
    sharedModules = [
      ./configuration.nix
      home-manager.nixosModules.home-manager
      {
        home-manager.useUserPackages = true;
        home-manager.useGlobalPkgs = true;
        home-manager.backupFileExtension = "backup";
        home-manager.extraSpecialArgs = { inherit inputs; };
        home-manager.users.chh = import ./home.nix;
      }
    ];
  in {
    nixosConfigurations = {
      # Bestehendes System (VM1)
      nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = sharedModules ++ [
          ./hosts/nixos/default.nix
          {
            networking.hostName = "nixos";
          }
        ];
      };

      # Neues System (Gen2)
      Gen2 = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = sharedModules ++ [
          ./hosts/Gen2/default.nix
          {
            networking.hostName = "Gen2";
          }
        ];
      };
    };
  };
}


