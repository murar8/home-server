{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    dotfiles = {
      url = "github:murar8/dotfiles";
      flake = false;
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      lanzaboote,
      impermanence,
      dotfiles,
      treefmt-nix,
      git-hooks,
      ...
    }:
    {
      nixosConfigurations.server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit dotfiles; };
        modules = [
          disko.nixosModules.disko
          lanzaboote.nixosModules.lanzaboote
          impermanence.nixosModules.impermanence
          ./configuration.nix
        ];
      };

      formatter.x86_64-linux =
        (treefmt-nix.lib.evalModule nixpkgs.legacyPackages.x86_64-linux ./treefmt.nix).config.build.wrapper;

      checks.x86_64-linux.git-hooks = git-hooks.lib.x86_64-linux.run {
        src = ./.;
        hooks = {
          treefmt = {
            enable = true;
            package = self.formatter.x86_64-linux;
          };
          statix.enable = true;
          nil = {
            enable = true;
            settings.denyWarnings = true;
          };
          markdownlint.enable = true;
        };
      };

      devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
        inherit (self.checks.x86_64-linux.git-hooks) shellHook;
        packages = with nixpkgs.legacyPackages.x86_64-linux; [
          statix
          nil
        ];
      };
    };
}
