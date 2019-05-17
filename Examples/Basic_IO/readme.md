# Example - Basic IO

The script monitors the six digital inputs at intervals of 250 ms, records the measurement data if one of the levels at the inputs 
changes and transfers these to the [Cloud server](https://cloud.microtronics.com). In addition to the digital inputs, there are two digital outputs for which the 
setpoints can be configured. Even modifying these setpoints will result in the measurement data being recorded and transferred. In 
addition to the levels at the six digital inputs, the current setpoints for both of the digital outputs and the battery voltage, USB 
charging voltage, temperature and GSM signal strength are recorded. 

The digital inputs and digital outputs can be deactivated 
individually via the configuration. Measurement values for deactivated inputs/outputs are set to "NaN" in the measurement data record. 
The connection type can also be configured. If the "online" connection type is selected, the measurement data is transmitted to the 
server as soon as the measurement data is created. When using one of the two other connection types ("Interval" or "Wakeup"), a 
connection establishment is triggered once the measurement data record is created so that the data can subsequently be transmitted to 
the server. 

In addition to the event-triggered connection establishment (level change at digital input or new setpoint for the digital
 output), an interval for transferring the measurement data can be configured. The measurement data is also recorded immediately before
 this interval expires regardless of whether one of the levels at the inputs has changed. 
 
 The current operating state is indicated by 
the RGB-LED. The LED lights up blue if there is an existing connection with the cloud server. The LED flickers blue while the 
connection is being established. If the last connection attempt failed, the LED flashes red until the next attempt to establish a 
connection. However, if the last connection was established successfully and the module is waiting for the next contact with the server
 (e.g. during "Interval" connection mode), then the LED is switched off. A connection to the server is either triggered automatically 
by the device following expiry of the transmission interval, receipt of a wakeup SMS, a level change at the digital input, the setpoint
 for the digital output being set, or manually by pressing the button. The measurement data is also recorded when the button is pressed. 

> **Please note:** Digital inputs 5 and 6 were implemented via the universal inputs. The energy consumption increases with each universal input that is initialised. 
For applications where the energy consumption is taken into consideration, these two inputs should not be used or should be deactivated, if possible.

The script generates and transmits the following measurement values:

| Measurement value:   | Unit: | Explanation:                                                                                                                                                                                                                                                                 |
|----------------------|-------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Digital input 1      | ---   | Levels at the input 1|
| Digital input 2      | ---   | Levels at the input 2|
| Digital input 3      | ---   | Levels at the input 3|
| Digital input 4      | ---   | Levels at the input 4|
| Digital input 5      | ---   | Levels at the input 5|
| Digital input 6      | ---   | Levels at the input 6|
| Digital output 1     | ---   | Setpoint of the digital output 1|
| Digital output 2     | ---   | Setpoint of the digital output 2|
| Battery voltage      | mV    | Voltage at the rechargeable battery connection of the [rapidM2M M3](https://www.microtronics.com/en/products/rapidM2M_M3.html). </br> If the rapidM2M M3 is charged via USB, the measurement value corresponds to the charging voltage. Otherwise, the measurement value corresponds to the voltage of the connected rechargeable battery. |
| USB charging voltage | mV    | Voltage at the USB connection of the rapidM2M M3                                                                                                                                                                                                                             |
| Temperature          | 0.1°C | Measurement value read out from the TMP112 (IC5) temperature sensor of the rapidM2M M3                                                                                                                                                                                        |
| GSM signal strength  | dBm   | Measurement value read at the time of the last established connection |

The script provides the following configuration options:

Input Channel Settings: 
Each the 6 individual input can be configured as follows:

| Parameter:            | Unit: | Explanation:                                                                                                                                                                                                                                                                      |
|-----------------------|-------|----------------------------------|
| Name of digital input | ---   | Name of respective digital input |
| Digital input			| ---	| (De-)Activation of digital inputs </br> 0: Input is activated </br> 1: Input is deactivated|

Output Channel Settings: 
Each of the two individual output can be configured as follows:

| Parameter:            | Unit: | Explanation:                                                                                                                                                                                                                                                                      |
|-----------------------|-------|----------------------------------|
| Name of digital output| ---   | Name of digital output|
| Digital output 		| ---	| (De-)Activation of digital output </br> 0: Output is activated </br> 1: Output is deactivated|
| Setpoint				| ---	| Setpoint that should be issued </br> 0: Output level set to "low" </br> 1: Output level set to "high"	   |

Basic settings:

| Parameter:            | Unit: | Explanation:                                                                                                                                                                                                                                                                      |
|-----------------------|-------|----------------------------------|
| Transmission interval | sec.  | Time between transmissions                                                                                                                                                                                                                                                        |
| Connection type       | ---   | 0: The device connects in the transmission cycle. </br> 1: The device connects in the transmission cycle. However, a connection can also be initiated through the server. </br> 2: The device does not disconnect the connection and continuously transmits the measurement data.</br> |


