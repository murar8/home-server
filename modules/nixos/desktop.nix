{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  programs.nix-ld.enable = true;

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
  };

  environment.sessionVariables = {
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
    usbutils

    # utilities
    bitwarden-cli
    bitwarden-desktop
    mongodb-compass
    scrcpy
  ];

}
