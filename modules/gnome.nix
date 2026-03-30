{
  lib,
  pkgs,
  vars,
  ...
}:

let
  dconfSettings = import ./dconf-settings.nix { inherit lib; };
  dconfKeys = lib.concatMap (
    section: map (key: "/${section}/${key}") (builtins.attrNames dconfSettings.${section})
  ) (builtins.attrNames dconfSettings);
in

{
  services = {
    displayManager = {
      gdm = {
        enable = true;
        wayland = true;
      };
      autoLogin = {
        enable = true;
        inherit (vars) user;
      };
    };
    desktopManager.gnome.enable = true;
    gnome.core-apps.enable = false;
  };

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  # Reset managed dconf keys in user db on login so stale values don't
  # diverge from the locked system profile.
  systemd.user.services.dconf-reset = {
    description = "Reset managed dconf keys in user db";
    wantedBy = [ "graphical-session.target" ];
    after = [ "dbus.socket" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = toString (
        pkgs.writeShellScript "dconf-reset" (
          builtins.concatStringsSep "\n" (map (k: "${pkgs.dconf}/bin/dconf reset ${k}") dconfKeys)
        )
      );
    };
  };

  programs.dconf.profiles.user.databases = [
    {
      lockAll = true;
      settings = dconfSettings;
    }
  ];

  environment.systemPackages = with pkgs; [
    adw-gtk3
    nautilus
    seahorse

    # gnome extensions
    gnomeExtensions.alphabetical-app-grid
    gnomeExtensions.appindicator
    gnomeExtensions.auto-power-profile
    gnomeExtensions.caffeine
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.dash-to-dock
    gnomeExtensions.easy-docker-containers
    gnomeExtensions.focus-changer
    gnomeExtensions.gsconnect
    gnomeExtensions.junk-notification-cleaner
    gnomeExtensions.bing-wallpaper-changer
    gnomeExtensions.space-bar
    gnomeExtensions.syncthing-toggle
    gnomeExtensions.tailscale-status
    gnomeExtensions.vitals
  ];
}
