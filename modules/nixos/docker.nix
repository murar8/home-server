{ config, pkgs, ... }:

{
  virtualisation.docker.enable = true;
  users.users.${config.local.user}.extraGroups = [ "docker" ];
  environment.systemPackages = [ pkgs.lazydocker ];
}
