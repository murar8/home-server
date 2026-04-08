{
  config,
  lib,
  pkgs,
  ...
}:

{
  nixpkgs.config.allowUnfree = true;

  i18n = {
    defaultLocale = config.local.locale;
    inherit (config.local) supportedLocales;
  };

  console.keyMap = "us";

  services.xserver.xkb.layout = "us";

  users.users.${config.local.user}.extraGroups = [ "docker" ];

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

  security.sudo.extraConfig = "Defaults timestamp_timeout=30";

  hardware = {
    enableRedistributableFirmware = true;
    bluetooth.enable = true;
    graphics.enable = true;
  };

  services = {
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

    tailscale = {
      enable = true;
      extraSetFlags = [ "--operator=${config.local.user}" ];
    };

    syncthing = {
      enable = true;
      inherit (config.local) user;
      dataDir = "/home/${config.local.user}";
      openDefaultPorts = true;
      systemService = false;
    };

    envfs.enable = true;
    fwupd.enable = true;
  };

  virtualisation.docker.enable = true;

  programs.nix-ld.enable = true;

  environment.sessionVariables = {
    PATH = [ "$HOME/.local/bin" ];
    SSH_AUTH_SOCK = "$HOME/.bitwarden-ssh-agent.sock";
    # libxkbcommon needs this to find compose tables for the compose key
    XLOCALEDIR = "${pkgs.xorg.libX11}/share/X11/locale";
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
    imagemagick
    jq
    lazydocker
    lazygit
    ripgrep
    rsync
    sox
    wget
    wl-clipboard

    # system
    e2fsprogs
    htop
    lsof
    pciutils
    sbctl
    usbutils

    # utilities
    bitwarden-cli
    bitwarden-desktop
    mongodb-compass
    scrcpy
  ];

}
