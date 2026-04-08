{ inputs, ... }:

{
  mkWindowsVM = import ./mk-windows-vm.nix { inherit (inputs) NixVirt; };
}
