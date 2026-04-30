{
  config,
  inputs,
  pkgs,
  ...
}:

let
  keyMap = "us";
in
{
  environment.systemPackages = [
    pkgs.git
    pkgs.nano
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.neovim
    pkgs.rsync
    pkgs.shh
  ];

  system.stateVersion = "25.11";

  # https://xeiaso.net/blog/paranoid-nixos-2021-07-18/
  # Universal hardening (not covered by lynis since these aren't sysctls):
  # keep service accounts out of the nix daemon, and prevent non-wheel users
  # from invoking the sudo binary at all.
  nix.settings.allowed-users = [ "@wheel" ];
  security.sudo.execWheelOnly = true;

  networking.nameservers = [
    "9.9.9.9"
    "149.112.112.112"
  ];

  time.timeZone = "Europe/Madrid";

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

  users.users.${config.local.user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ config.local.sshKey ];
  };

  programs.bash.loginShellInit = ''
    [ -f ~/.bashrc ] && . ~/.bashrc
  '';

  i18n = {
    defaultLocale = "es_ES.UTF-8";
    supportedLocales = [
      "es_ES.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
  };

  console.keyMap = keyMap;

  services.xserver.xkb.layout = keyMap;

  boot = {
    initrd.systemd.enable = true;
    loader.timeout = 1;
    tmp.useTmpfs = true;
    # Mountpoint workaround for envfs + systemd-initrd; identical to the fix
    # merged in nixpkgs#494001. Drop once that lands in nixos-25.11.
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
