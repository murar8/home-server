{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    impermanence.url = "github:nix-community/impermanence";
    neovim-bin = {
      url = "https://github.com/neovim/neovim/releases/download/v0.12.0/nvim-linux-x86_64.tar.gz";
      flake = false;
    };
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
    NixVirt = {
      url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      neovim-bin,
      disko,
      lanzaboote,
      impermanence,
      NixVirt,
      dotfiles,
      treefmt-nix,
      git-hooks,
      ...
    }:
    let
      commonModules = [
        ./modules/options.nix
        disko.nixosModules.disko
        lanzaboote.nixosModules.lanzaboote
        {
          nixpkgs.overlays = [
            (_: prev: {
              neovim = prev.stdenv.mkDerivation {
                pname = "neovim";
                version = "0.12.0";
                src = neovim-bin;
                nativeBuildInputs = [ prev.autoPatchelfHook ];
                buildInputs = [ prev.stdenv.cc.cc.lib ];
                installPhase = "cp -r . $out";
              };
            })
          ];
        }
      ];
    in
    {
      nixosConfigurations = {
        prodesk = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit dotfiles; };
          modules = commonModules ++ [
            impermanence.nixosModules.impermanence
            ./hosts/prodesk/configuration.nix
          ];
        };

        thinkpad = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit dotfiles; };
          modules = commonModules ++ [ ./hosts/thinkpad/configuration.nix ];
        };

        desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit dotfiles NixVirt; };
          modules = commonModules ++ [ ./hosts/desktop/configuration.nix ];
        };
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
