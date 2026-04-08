{ inputs, flake, ... }:

{
  imports = [
    flake.modules.nixos.options
    inputs.disko.nixosModules.disko
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  nixpkgs.overlays = [
    (_: prev: {
      neovim = prev.stdenv.mkDerivation {
        pname = "neovim";
        version = "0.12.0";
        src = inputs.neovim-bin;
        nativeBuildInputs = [ prev.autoPatchelfHook ];
        buildInputs = [ prev.stdenv.cc.cc.lib ];
        installPhase = "cp -r . $out";
      };
    })
  ];
}
