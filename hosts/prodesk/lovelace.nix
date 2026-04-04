{
  views = [
    {
      type = "sections";
      title = "Garden";
      path = "garden";
      icon = "mdi:sprout";
      max_columns = 2;
      sections =
        let
          heading = h: icon: [
            {
              type = "heading";
              heading = h;
              inherit icon;
            }
          ];
          subtitle = h: [
            {
              type = "heading";
              heading = h;
              heading_style = "subtitle";
            }
          ];
          tile = entity: name: {
            type = "tile";
            inherit entity name;
          };
          plantSection = label: suffix: {
            cards =
              (heading label "mdi:flower")
              ++ [
                (tile "sensor.esp_garden_soil_moisture_${suffix}" "Soil Moisture")
                (tile "number.esp_garden_water_volume_${suffix}" "Water Volume")
              ]
              ++ (subtitle "Watering")
              ++ [
                (tile "button.esp_garden_water_plant_${suffix}" "Water")
                (tile "button.esp_garden_stop_watering_${suffix}" "Stop")
                (tile "sensor.esp_garden_next_watering_${suffix}" "Next Watering")
                (tile "sensor.esp_garden_last_watering_${suffix}" "Last Watering")
              ]
              ++ (subtitle "Water Tank")
              ++ [
                (tile "sensor.esp_garden_water_level_${suffix}" "Water Level")
                (tile "binary_sensor.esp_garden_water_low_${suffix}" "Water Low")
              ]
              ++ (subtitle "Volume")
              ++ [
                (tile "sensor.plant_${suffix}_hourly" "This Hour")
                (tile "sensor.plant_${suffix}_daily" "Today")
                (tile "sensor.plant_${suffix}_weekly" "This Week")
                (tile "sensor.plant_${suffix}_monthly" "This Month")
              ]
              ++ (subtitle "Pump")
              ++ [
                (tile "fan.esp_garden_pump_${suffix}" "Pump")
                (tile "sensor.esp_garden_total_water_dispensed_${suffix}" "Total Dispensed")
              ]
              ++ (subtitle "Faults")
              ++ [
                (tile "binary_sensor.esp_garden_sensor_fault_${suffix}" "Soil Fault")
                (tile "binary_sensor.esp_garden_water_level_fault_${suffix}" "Water Level Fault")
              ];
          };
        in
        [
          {
            cards = (heading "Global" "mdi:cog") ++ [
              (tile "select.esp_garden_watering_interval" "Watering Interval")
            ];
          }
          {
            cards = (heading "Device" "mdi:chip") ++ [
              (tile "sensor.esp_garden_wifi_signal" "WiFi Signal")
              (tile "sensor.esp_garden_uptime" "Uptime")
            ];
          }
          (plantSection "Plant A" "a")
          (plantSection "Plant B" "b")
        ];
    }
  ];
}
