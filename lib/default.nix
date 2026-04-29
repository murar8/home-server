{ inputs, ... }:

let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
in
{
  mkWindowsVM = import ./mk-windows-vm.nix {
    inherit (inputs) NixVirt;
    inherit pkgs;
  };
}
