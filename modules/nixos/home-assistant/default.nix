{ config, ... }:

{
  environment.persistence."/persist".directories = [ "/var/lib/hass" ];

  networking.firewall.interfaces.${config.local.net.interface}.allowedTCPPorts = [
    config.services.home-assistant.config.http.server_port
  ];

  services.home-assistant = {
    enable = true;
    extraComponents = [
      "esphome"
      "met"
      "isal"
    ];
    config = {
      default_config = { };
      logger.default = "info";
      lovelace.mode = "yaml";
      homeassistant = {
        name = "Home";
        unit_system = "metric";
        internal_url = "http://${config.local.net.ip}:${toString config.services.home-assistant.config.http.server_port}";
      };
    };
    lovelaceConfig = import ./lovelace.nix;
    config.utility_meter =
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
}
