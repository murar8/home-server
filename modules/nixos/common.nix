{ inputs, flake, ... }:

{
  imports = [
    flake.modules.nixos.options
    flake.modules.nixos.base
    flake.modules.nixos.dotfiles
    flake.modules.nixos.hardening-common
    flake.modules.nixos.secure-boot
    flake.modules.nixos.ssh
    inputs.disko.nixosModules.disko
    inputs.lanzaboote.nixosModules.lanzaboote
  ];
}
