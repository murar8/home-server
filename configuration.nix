{
  config,
  lib,
  pkgs,
  dotfiles,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.11";

  networking = {
    hostName = "thinkpad";
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/Madrid";

  i18n = {
    defaultLocale = "es_ES.UTF-8";
    supportedLocales = [
      "es_ES.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
  };

  console.keyMap = "us";

  services.xserver.xkb = {
    layout = "us";
    # lv3:ralt_alt — right alt acts as normal alt (not AltGr)
    # compose:ralt — right alt also serves as compose key (for accented characters)
    options = "lv3:ralt_alt,compose:ralt";
  };

  users.users.murar8 = {
    isNormalUser = true;
    initialHashedPassword = "$6$U//rqA7xCeod5xl5$/JSOS7xH1gMOJcP8zJmom7dnnDdPyPu1UWY2qFE/UEaUP5vpEPxbfPXJL2e8ws6WSG4GKwlbHu5rs4Wa1.hoK0";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKCfqnufJrf3pZxXvFcqbB1vUhyc0EFuDBuUEO7Q0Luq lnzmrr@gmail.com"
    ];
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  boot = {
    initrd.systemd.enable = true;
    loader = {
      timeout = 1;
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = true;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      autoGenerateKeys.enable = true;
      autoEnrollKeys.enable = true;
    };
    tmp.useTmpfs = true;
  };

  hardware = {
    enableRedistributableFirmware = true;
    bluetooth.enable = true;
  };

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

    fprintd.enable = true;

    printing.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "*" ];
        settings = {
          main.capslock = "overloadt(capslock, esc, 200)";
          capslock = {
            h = "left";
            j = "down";
            k = "up";
            l = "right";
          };
        };
      };
    };

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    tailscale.enable = true;

    syncthing = {
      enable = true;
      user = "murar8";
      dataDir = "/home/murar8";
      openDefaultPorts = true;
    };

    btrfs.autoScrub.enable = true;
    fwupd.enable = true;
  };

  programs.dconf.profiles.user.databases = [
    {
      lockAll = true;
      keyfiles = [ ./dconf ];
    }
  ];

  # https://github.com/NixOS/nixpkgs/issues/171136
  # https://wiki.nixos.org/wiki/Fingerprint_scanner
  # fprintd disables password login in GDM without this workaround
  security.pam.services.login.fprintAuth = false;
  security.pam.services.gdm-fingerprint = lib.mkIf config.services.fprintd.enable {
    text = ''
      auth       required                    pam_shells.so
      auth       requisite                   pam_nologin.so
      auth       requisite                   pam_faillock.so      preauth
      auth       required                    ${pkgs.fprintd}/lib/security/pam_fprintd.so
      auth       optional                    pam_permit.so
      auth       required                    pam_env.so
      auth       [success=ok default=1]      ${pkgs.gdm}/lib/security/pam_gdm.so
      auth       optional                    ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so

      account    include                     login

      password   required                    pam_deny.so

      session    include                     login
      session    optional                    ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so auto_start
    '';
  };

  virtualisation.docker.enable = true;

  programs.bash.loginShellInit = ''
    [ -f ~/.bashrc ] && . ~/.bashrc
  '';

  environment.systemPackages = with pkgs; [
    # browsers
    # firefox
    google-chrome

    # communication
    discord

    # terminals & editors
    ghostty
    neovim
    nano
    gcc
    tree-sitter
    nodejs
    unzip
    python3

    # system
    sbctl

    # cli tools
    git
    delta
    lazygit
    lazydocker
    ripgrep
    fd
    fzf
    jq
    curl
    wget
    rsync
    direnv

    # media
    # vlc

    # utilities
    bitwarden-desktop
    seahorse
    gnomeExtensions.alphabetical-app-grid
    gnomeExtensions.appindicator
    gnomeExtensions.bing-wallpaper
    gnomeExtensions.caffeine
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.dash-to-dock
    gnomeExtensions.easy-docker-containers
    gnomeExtensions.focus-changer
    gnomeExtensions.gsconnect
    gnomeExtensions.junk-notification-cleaner
    gnomeExtensions.legacy-gtk3-theme-scheme-auto-switcher
    gnomeExtensions.space-bar
    gnomeExtensions.syncthing-indicator
    gnomeExtensions.syncthing-toggle
    gnomeExtensions.tailscale-status
    gnomeExtensions.tiling-assistant
    gnomeExtensions.vitals
    scrcpy

    # cloud & devops
    # terraform
    # kubectl
    # mongosh

    # security
    # tor-browser
  ];

  systemd.services.dotfiles-checkout = {
    description = "Checkout dotfiles into home directory";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "murar8";
      Group = "users";
    };
    path = with pkgs; [
      git
      openssh
    ];
    script = builtins.readFile "${dotfiles}/.bootstrap";
  };
}
