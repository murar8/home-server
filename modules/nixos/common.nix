{ inputs, flake, ... }:

{
  imports = [
    flake.modules.nixos.options
    flake.modules.nixos.base
    inputs.disko.nixosModules.disko
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  nixpkgs.overlays = [
    (_: prev: {
      neovim = prev.stdenv.mkDerivation {
        pname = "neovim";
        version = "0.12.0"; # keep in sync with neovim-bin input URL in flake.nix
        src = inputs.neovim-bin;
        nativeBuildInputs = [ prev.autoPatchelfHook ];
        buildInputs = [ prev.stdenv.cc.cc.lib ];
        installPhase = "cp -r . $out";
      };
    })
  ];
}
