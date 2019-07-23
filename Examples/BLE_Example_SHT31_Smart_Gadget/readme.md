# Example - BLE SHT31 Smart Gadget

![!Example - BLE SHT31 Smart Gadget](https://support.microtronics.com/pictures/rapidM2M-IoT-Box_BLE_Example_SHT31_Smart_Gadget.jpg)

The script is designed to read the current temperature and humidity for a “Sensirion SHT31 Smart Gadget” 
via Bluetooth Low Energy. The determined values are issued every 4sec. via the console so that they can 
be displayed using the “Console” Tab of the [rapidM2M Toolset](https://www.microtronics.com/en/service/toolset.html). The scan for BLE devices and the following
connection to the “Sensirion SHT31 Smart Gadget” found is triggered by pressing the button of the 
[rapidM2M M3](https://www.microtronics.com/en/products/rapidM2M_M3.html). After pressing the button, the LED of the rapidM2M M3 starts to flash blue. When the 
connection is established the LED lights up blue. The BLE connection is terminated by pressing the button 
of the rapidM2M M3 again. Following this, the LED is switched off.

> **Important note:** Before the initialization of the BLE scan, the BLE module of the 
“Sensirion SHT31 Smart Gadget” must be activated by pressing the 
button of the “Sensirion SHT31 Smart Gadget” for at least 1sec. 

The script generates the following measurement values and issues them via the console

| Measurement value:   | Unit: | Explanation:                                                                                                                                                                                                                                                                 |
|----------------------|-------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Humidity			   | %     | Humidity read out from the "Sensirion SHT31 Smart Gadget"                                                                                                                                                                                                                          |
| Temperature          | °C    | Temperature read out from the "Sensirion SHT31 Smart Gadget"                                                                                                                                                                                        |
