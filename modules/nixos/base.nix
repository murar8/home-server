{
  config,
  inputs,
  pkgs,
  ...
}:

{
  environment.systemPackages = [
    pkgs.git
    pkgs.nano
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.neovim
    pkgs.rsync
  ];

  system.stateVersion = config.local.stateVersion;

  networking.nameservers = config.local.nameservers;

  time.timeZone = config.local.timeZone;

  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  users.users.${config.local.user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ config.local.sshKey ];
  };

  programs.bash.loginShellInit = ''
    [ -f ~/.bashrc ] && . ~/.bashrc
  '';

  i18n = {
    defaultLocale = config.local.locale;
    inherit (config.local) supportedLocales;
  };

  console.keyMap = config.local.keyMap;

  services.xserver.xkb.layout = config.local.keyMap;

  boot = {
    initrd.systemd.enable = true;
    loader.timeout = 1;
    tmp.useTmpfs = true;
    # TODO: remove when nixpkgs#494001 is backported to nixos-25.11
    initrd.systemd.tmpfiles.settings."50-envfs" = {
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

  hardware.enableRedistributableFirmware = true;

  services = {
    btrfs.autoScrub.enable = true;
    envfs.enable = true;
    fwupd.enable = true;
    smartd.enable = true;
  };

}
