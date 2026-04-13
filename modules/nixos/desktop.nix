{ pkgs, inputs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  programs.nix-ld.enable = true;

  hardware = {
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

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
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

    # ai
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code

    # terminals & editors
    ghostty
    nodejs
    python3
    tree-sitter
    unzip

    # dev tools
    gcc

    # cli tools
    curl
    delta
    fd
    fzf
    gh
    imagemagick
    jq
    lazygit
    ripgrep
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
