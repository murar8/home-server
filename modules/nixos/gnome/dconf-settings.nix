{ lib }:

let
  inherit (lib.gvariant)
    mkInt32
    mkUint32
    mkDouble
    mkEmptyArray
    type
    ;
  emptyAs = mkEmptyArray type.string;
in
{
  "org/gnome/desktop/datetime" = {
    automatic-timezone = true;
  };

  "org/gnome/desktop/interface" = {
    accent-color = "purple";
    clock-format = "24h";
    color-scheme = "prefer-dark";
    gtk-theme = "adw-gtk3-dark";
  };

  "org/gnome/desktop/input-sources" = {
    xkb-options = [ "compose:ralt" ];
  };

  "org/gnome/desktop/peripherals/keyboard" = {
    numlock-state = true;
    remember-numlock-state = true;
  };

  "org/gnome/desktop/peripherals/touchpad" = {
    natural-scroll = true;
    tap-to-click = true;
  };

  "org/gnome/desktop/screensaver" = {
    lock-delay = mkUint32 300;
  };

  "org/gnome/desktop/session" = {
    idle-delay = mkUint32 900;
  };

  "org/gnome/desktop/wm/keybindings" = {
    # Super+q = close (frees from Alt+F4 only)
    close = [
      "<Super>q"
      "<Alt>F4"
    ];

    # Super+f = fullscreen, Super+r = resize, Super+m = move
    toggle-fullscreen = [ "<Super>f" ];
    begin-resize = [ "<Super>r" ];
    begin-move = [ "<Super>m" ];

    # Super+Ctrl+dir = maximize/unmaximize (moved off Super+Up/Down for focus-changer)
    maximize = [
      "<Control><Super>Up"
      "<Control><Super>k"
    ];
    unmaximize = [
      "<Control><Super>Down"
      "<Control><Super>j"
    ];

    # Super+Shift+dir = move to monitor (add hjkl alternatives)
    move-to-monitor-left = [
      "<Super><Shift>Left"
      "<Super><Shift>h"
    ];
    move-to-monitor-right = [
      "<Super><Shift>Right"
      "<Super><Shift>l"
    ];
    move-to-monitor-up = [
      "<Super><Shift>Up"
      "<Super><Shift>k"
    ];
    move-to-monitor-down = [
      "<Super><Shift>Down"
      "<Super><Shift>j"
    ];

    # Super+Alt+dir = workspace left/right (add hjkl, keep Page keys)
    switch-to-workspace-left = [
      "<Super><Alt>Left"
      "<Super><Alt>h"
      "<Super>Page_Up"
    ];
    switch-to-workspace-right = [
      "<Super><Alt>Right"
      "<Super><Alt>l"
      "<Super>Page_Down"
    ];
    move-to-workspace-left = [
      "<Super><Shift><Alt>Left"
      "<Super><Shift><Alt>h"
      "<Super><Shift>Page_Up"
    ];
    move-to-workspace-right = [
      "<Super><Shift><Alt>Right"
      "<Super><Shift><Alt>l"
      "<Super><Shift>Page_Down"
    ];
  }
  # Super+N = switch to workspace N, Super+Shift+N = move to workspace N
  // lib.genAttrs (map (n: "switch-to-workspace-${toString n}") (lib.range 1 10)) (
    name:
    let
      n = lib.removePrefix "switch-to-workspace-" name;
      key = if n == "10" then "0" else n;
    in
    [ "<Super>${key}" ]
  )
  // lib.genAttrs (map (n: "move-to-workspace-${toString n}") (lib.range 1 10)) (
    name:
    let
      n = lib.removePrefix "move-to-workspace-" name;
      key = if n == "10" then "0" else n;
    in
    [ "<Shift><Super>${key}" ]
  )
  // {

    # Alt+Tab = flat window list, Super+Tab = grouped by app
    switch-windows = [ "<Alt>Tab" ];
    switch-windows-backward = [ "<Shift><Alt>Tab" ];
    switch-applications = [ "<Super>Tab" ];
    switch-applications-backward = [ "<Shift><Super>Tab" ];

    # Disable to free Super+h for focus-changer
    minimize = emptyAs;
    # Remove Super+Above_Tab to free Super+grave for space-bar
    switch-group = [ "<Alt>Above_Tab" ];
    switch-group-backward = [ "<Shift><Alt>Above_Tab" ];
  };

  "org/gnome/desktop/wm/preferences" = {
    num-workspaces = mkInt32 10;
  };

  "org/gnome/mutter" = {
    dynamic-workspaces = false;
    edge-tiling = true;
    experimental-features = [
      "scale-monitor-framebuffer"
      "xwayland-native-scaling"
      "variable-refresh-rate"
      "autoclose-xwayland"
    ];
    workspaces-only-on-primary = true;
  };

  # Super+Ctrl+dir = tile left/right half (moved off Super+Left/Right for focus-changer)
  "org/gnome/mutter/keybindings" = {
    toggle-tiled-left = [
      "<Control><Super>Left"
      "<Control><Super>h"
    ];
    toggle-tiled-right = [
      "<Control><Super>Right"
      "<Control><Super>l"
    ];
  };

  "org/gnome/nautilus/preferences" = {
    default-folder-viewer = "list-view";
    migrated-gtk-settings = true;
  };

  "org/gnome/settings-daemon/plugins/color" = {
    night-light-enabled = true;
    night-light-schedule-automatic = false;
    night-light-schedule-from = mkDouble 22.0;
    night-light-temperature = mkUint32 3700;
  };

  "org/gnome/settings-daemon/plugins/media-keys" = {
    screensaver = [ "<Super>Escape" ];
    home = [ "<Super>e" ];
    www = [ "<Super>b" ];
    volume-up = [ "<Super>F10" ];
    volume-down = [ "<Super>F11" ];
    volume-mute = [ "<Super>F12" ];
    custom-keybindings = [
      "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
    ];
  };

  "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
    name = "Terminal";
    command = "ghostty";
    binding = "<Super>Return";
  };

  "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
    name = "Slack";
    command = "slack";
    binding = "<Super>c";
  };

  "org/gnome/settings-daemon/plugins/power" = {
    power-button-action = "suspend";
    sleep-inactive-ac-timeout = mkInt32 1800;
    sleep-inactive-ac-type = "suspend";
  };

  "org/gnome/shell" = {
    disable-user-extensions = false;
    enabled-extensions = [
      "AlphabeticalAppGrid@stuarthayhurst"
      "BingWallpaper@ineffable-gmail.com"
      "Vitals@CoreCoding.com"
      "appindicatorsupport@rgcjonas.gmail.com"
      "auto-power-profile@dmy3k.github.io"
      "caffeine@patapon.info"
      "clipboard-indicator@tudmotu.com"
      "dash-to-dock@micxgx.gmail.com"
      "easy_docker_containers@red.software.systems"
      "focus-changer@heartmire"
      "gsconnect@andyholmes.github.io"
      "junk-notification-cleaner@murar8.github.com"
      "space-bar@luchrioh"
      "syncthing-toggle@rehhouari.github.com"
      "tailscale-status@maxgallup.github.com"
    ];
    favorite-apps = [
      "google-chrome.desktop"
      "com.mitchellh.ghostty.desktop"
      "org.gnome.Nautilus.desktop"
      "org.gnome.Settings.desktop"
    ];
  };

  "org/gnome/shell/keybindings" =
    # Disable to free Super+1-9 for workspace switching
    lib.genAttrs (map (n: "switch-to-application-${toString n}") (lib.range 1 9)) (_: emptyAs) // {
      # Disable to free Super+n for workspace switching
      focus-active-notification = emptyAs;
      # Disable Super+v (clipboard) and Super+m (begin-move) aliases
      toggle-message-tray = emptyAs;
    };

  "org/gnome/shell/extensions/caffeine" = {
    inhibit-apps = [
      "virt-manager.desktop"
      "slack.desktop"
    ];
    nightlight-control = "always";
    use-custom-duration = true;
    user-enabled = true;
  };

  "org/gnome/shell/extensions/clipboard-indicator" = {
    cache-size = mkInt32 32;
    display-mode = mkInt32 2;
    enable-keybindings = true;
    excluded-apps = [ "Bitwarden" ];
    history-size = mkInt32 200;
    move-item-first = true;
    next-entry = [ "<Super>v" ];
    notify-on-cycle = false;
    prev-entry = [ "<Super><Shift>v" ];
    regex-search = true;
    toggle-menu = [ "<Super><Alt>v" ];
    clear-history = emptyAs;
    private-mode-binding = emptyAs;
    pinned-on-bottom = false;
    preview-size = mkInt32 60;
    strip-text = true;
  };

  "org/gnome/shell/extensions/dash-to-dock" =
    # Disable to free Super+1-0 for space-bar workspace switching
    lib.genAttrs (lib.concatMap (prefix: map (n: "${prefix}-${toString n}") (lib.range 1 10)) [
      "app-hotkey"
      "app-shift-hotkey"
      "app-ctrl-hotkey"
    ]) (_: emptyAs)
    // {
      autohide = true;
      autohide-in-fullscreen = false;
      dock-position = "BOTTOM";
      hot-keys = false;
      # Disable to free Super+q for close window
      shortcut = emptyAs;
      intellihide = true;
      intellihide-mode = "FOCUS_APPLICATION_WINDOWS";
      isolate-monitors = true;
      isolate-workspaces = true;
      multi-monitor = true;
      require-pressure-to-show = true;
      scroll-action = "cycle-windows";
      show-mounts-network = false;
      show-mounts-only-mounted = true;
      show-trash = false;
      transparency-mode = "DYNAMIC";
    };

  "org/gnome/shell/extensions/focus-changer" = {
    focus-left = [
      "<Super>Left"
      "<Super>h"
    ];
    focus-down = [
      "<Super>Down"
      "<Super>j"
    ];
    focus-up = [
      "<Super>Up"
      "<Super>k"
    ];
    focus-right = [
      "<Super>Right"
      "<Super>l"
    ];
  };

  "org/gnome/shell/extensions/junk-notification-cleaner" = {
    delete-on-close = true;
    delete-on-focus = true;
    excluded-apps = emptyAs;
    show-persistent-notification = false;
  };

  "org/gnome/shell/extensions/space-bar/appearance" = {
    always-show-numbers = true;
    workspace-margin = mkInt32 4;
    workspaces-bar-padding = mkInt32 4;
  };

  "org/gnome/shell/extensions/space-bar/behavior" = {
    always-show-numbers = true;
    indicator-style = "workspaces-bar";
    show-empty-workspaces = false;
    smart-workspace-names = false;
    system-workspace-indicator = false;
  };

  "org/gnome/shell/extensions/space-bar/shortcuts" =
    # Reset space-bar's workspace shortcut keys so stale user-db values
    # don't shadow the locked system profile (native WM keybindings used instead).
    lib.genAttrs (
      map (n: "activate-workspace-${toString n}") (lib.range 1 10)
      ++ map (n: "move-to-workspace-${toString n}") (lib.range 1 10)
    ) (_: emptyAs)
    // {
      enable-activate-workspace-shortcuts = false;
      enable-move-to-workspace-shortcuts = false;
      move-workspace-left = [ "<Super>bracketleft" ];
      move-workspace-right = [ "<Super>bracketright" ];
    };

  "org/gnome/shell/extensions/vitals" = {
    alphabetize = true;
    fixed-widths = true;
    hot-sensors = [
      "_memory_usage_"
      "_processor_usage_"
      "_temperature_k10temp_tctl_"
    ];
    position-in-panel = mkInt32 1;
    show-fan = false;
    show-gpu = false;
    show-memory = true;
    show-network = false;
    show-storage = false;
    show-system = false;
    show-temperature = true;
    show-voltage = false;
  };

  "org/gtk/gtk4/settings/file-chooser" = {
    show-hidden = true;
  };

  "org/gtk/settings/file-chooser" = {
    show-hidden = true;
  };
}
