{
  config,
  lib,
  pkgs,
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
        inherit (config.local) user;
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
      ExecStart = lib.getExe (
        pkgs.writeShellApplication {
          name = "dconf-reset";
          runtimeInputs = [ pkgs.dconf ];
          text = builtins.concatStringsSep "\n" (map (k: "dconf reset '${k}'") dconfKeys);
        }
      );
    };
  };

  programs.dconf.profiles.user.databases = [
    {
      lockAll = true;
      settings = dconfSettings;
    }
  ];

  # GSConnect (KDE Connect) uses ports 1714-1764
  networking.firewall = {
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
  };

  xdg.mime.defaultApplications."text/plain" = "nvim.desktop";

  # Ghostty as the terminal glib launches for desktop entries with
  # Terminal=true (e.g. the stock nvim.desktop).
  xdg.terminal-exec = {
    enable = true;
    settings.default = [ "com.mitchellh.ghostty.desktop" ];
  };

  environment.systemPackages = with pkgs; [
    adw-gtk3
    gnome-calendar
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
    gnomeExtensions.bing-wallpaper-changer
    gnomeExtensions.space-bar
    gnomeExtensions.syncthing-toggle
    gnomeExtensions.tailscale-status
    gnomeExtensions.vitals
  ];
}
