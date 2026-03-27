{
  lib,
  pkgs,
  dotfiles,
  ...
}:

{
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.11";

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
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKCfqnufJrf3pZxXvFcqbB1vUhyc0EFuDBuUEO7Q0Luq lnzmrr@gmail.com"
    ];
    extraGroups = [
      "wheel"
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
    initrd.systemd = {
      enable = true;
      # TODO: remove when nixpkgs#494001 is backported to nixos-25.11
      tmpfiles.settings."50-envfs" = {
        "/sysroot/usr/bin".d = {
          group = "root";
          mode = "0755";
          user = "root";
        };
        "/sysroot/bin".d = {
          group = "root";
          mode = "0755";
          user = "root";
        };
      };
    };
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

    tailscale = {
      enable = true;
      extraSetFlags = [ "--operator=murar8" ];
    };

    syncthing = {
      enable = true;
      user = "murar8";
      dataDir = "/home/murar8";
      openDefaultPorts = true;
      systemService = false;
    };

    btrfs.autoScrub.enable = true;
    envfs.enable = true;
    fwupd.enable = true;
    gvfs.enable = true;
  };

  virtualisation.docker.enable = true;

  programs = {
    nix-ld.enable = true;
    bash.loginShellInit = ''
      [ -f ~/.bashrc ] && . ~/.bashrc
    '';
    dconf.profiles.user.databases = [
      {
        lockAll = true;
        keyfiles = [ ../dconf ];
      }
    ];
  };

  environment.sessionVariables = {
    PATH = [ "$HOME/.local/bin" ];
    SSH_AUTH_SOCK = "$HOME/.bitwarden-ssh-agent.sock";
  };

  environment.systemPackages = with pkgs; [
    # browsers
    google-chrome

    # communication
    discord
    slack

    # terminals & editors
    gcc
    ghostty
    nano
    neovim
    nodejs
    python3
    tree-sitter
    unzip

    # cli tools
    curl
    delta
    direnv
    fd
    fzf
    gh
    git
    jq
    lazydocker
    lazygit
    ripgrep
    rsync
    wget

    # system
    nautilus
    sbctl
    seahorse

    # utilities
    bitwarden-cli
    bitwarden-desktop
    scrcpy

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
    gnomeExtensions.picture-of-the-day
    gnomeExtensions.space-bar
    gnomeExtensions.syncthing-toggle
    gnomeExtensions.tailscale-status
    gnomeExtensions.tiling-assistant
    gnomeExtensions.vitals
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
