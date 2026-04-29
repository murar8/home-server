{ pkgs, inputs, ... }:

let
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
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
    # libxkbcommon needs this to find compose tables for the compose key
    XLOCALEDIR = "${pkgs.xorg.libX11}/share/X11/locale";
  };

  environment.systemPackages = with pkgs; [
    curl
    delta
    discord
    e2fsprogs
    fd
    fzf
    gcc
    gh
    ghostty
    google-chrome
    htop
    imagemagick
    jq
    lazygit
    llmAgents.claude-code
    llmAgents.opencode
    lsof
    mongodb-compass
    moonlight-qt
    nodejs
    pciutils
    python3
    ripgrep
    scrcpy
    slack
    tree-sitter
    unzip
    usbutils
    wget
    wl-clipboard
  ];

}
