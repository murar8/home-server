{ pkgs, ... }:

{
  services = {
    displayManager = {
      gdm = {
        enable = true;
        wayland = true;
      };
      autoLogin = {
        enable = true;
        user = "murar8";
      };
    };
    desktopManager.gnome.enable = true;
    gnome.core-apps.enable = false;
    gvfs.enable = true;
  };

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  programs.dconf.profiles.user.databases = [
    {
      lockAll = true;
      keyfiles = [ ../dconf ];
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
    gnomeExtensions.tiling-assistant
    gnomeExtensions.vitals
  ];
}
