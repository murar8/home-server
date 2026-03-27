{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    dotfiles = {
      url = "github:murar8/dotfiles";
      flake = false;
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
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
      neovim-nightly-overlay,
      disko,
      lanzaboote,
      dotfiles,
      treefmt-nix,
      git-hooks,
      ...
    }:
    let
      commonModules = [
        disko.nixosModules.disko
        lanzaboote.nixosModules.lanzaboote
        { nixpkgs.overlays = [ neovim-nightly-overlay.overlays.default ]; }
      ];
    in
    {
      nixosConfigurations.thinkpad = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit dotfiles; };
        modules = commonModules ++ [ ./hosts/thinkpad/configuration.nix ];
      };

      nixosConfigurations.debian = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit dotfiles; };
        modules = commonModules ++ [ ./hosts/debian/configuration.nix ];
      };

      formatter.x86_64-linux =
        (treefmt-nix.lib.evalModule nixpkgs.legacyPackages.x86_64-linux ./treefmt.nix).config.build.wrapper;

      checks.x86_64-linux.git-hooks = git-hooks.lib.x86_64-linux.run {
        src = ./.;
        hooks = {
          statix.enable = true;
          markdownlint.enable = true;
          nil = {
            enable = true;
            settings.denyWarnings = true;
          };
          treefmt = {
            enable = true;
            package = self.formatter.x86_64-linux;
          };
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
