{
  config,
  ...
}:

let
  inherit (import ./vars.nix) vars;
  fqdn = "${vars.hostname}.${vars.tailnet}";
in
{
  services.home-assistant = {
    enable = true;
    extraComponents = [
      "esphome"
      "met"
      "isal"
    ];
    config = {
      default_config = { };
      homeassistant = {
        name = "Home";
        unit_system = "metric";
        external_url = "https://${fqdn}";
        internal_url = "https://${fqdn}";
      };
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
      };
      logger.default = "info";
      lovelace.mode = "yaml";
      utility_meter =
        let
          plant = suffix: source: {
            "plant_${suffix}_hourly" = {
              inherit source;
              cycle = "hourly";
            };
            "plant_${suffix}_daily" = {
              inherit source;
              cycle = "daily";
            };
            "plant_${suffix}_weekly" = {
              inherit source;
              cycle = "weekly";
            };
            "plant_${suffix}_monthly" = {
              inherit source;
              cycle = "monthly";
            };
          };
        in
        (plant "a" "sensor.esp_garden_total_water_dispensed_a")
        // (plant "b" "sensor.esp_garden_total_water_dispensed_b");
    };
    lovelaceConfig = import ./lovelace.nix;
  };
}
