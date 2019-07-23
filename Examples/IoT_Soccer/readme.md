# Example - IoT Soccer

![!Example - IoT Soccer](https://support.microtronics.com/pictures/rapidM2M-IoT-Box_IoT_Soccer)


The script gathers pulses of signal sensors via the two universal inputs. For correct detection, these must have a duration of at least 
10ms. Every 250ms the counter readings of the two universal inputs are checked. If a universal input has detected at least one pulse the 
counter for the corresponding player is incremented by 1 and the monitoring of the universal inputs is stopped. I.e. the game is paused so
that you can remove the ball from the goal. 

The script also calculates the difference between the counters for player1 and player2 
(Player2 - Player1). I.e. When player2 leads the difference is positive. Every time the Monitoring is stopped the values of the 3 
counters (Player1, Player2 and difference) are recorded. If another connection type as "online" has been selected, a connection to the 
[Cloud Server](http://cloud.microtronics.com) is also established. The monitoring is activated again by pressing the button briefly (< 3sec.). If the Monitoring has been 
activated by briefly pressing the button (< 3sec.) a connection to the Cloud Server is triggered. By pressing the button for a long time 
(>3sec.) all 3 counters (Player1, Player2 and difference) are reset and recorded and if another connection type than "online" has been selected, 
a connection to the Cloud Server is also established. 

The interval for transmitting measurement data can be configured. The connection type can 
also be configured. If the "online" connection type is selected, the measurement data is transmitted to the Cloud Server as soon as the 
measurement data is created. 

The current operating state is indicated by the RGB-LED. The LED lights up (magenta if monitoring is active, yellow 
if monitoring is stopped) if there is an existing connection with the Cloud Server. The LED flickers (magenta if monitoring is active, yellow if 
monitoring is stopped) while the connection is being established. If the last connection attempt failed, the LED flashes red until the next 
attempt to establish a connection. However, if the last connection establishment was successful and the rapidM2M M3 is waiting for the next contact 
with the Cloud Server (e.g. during "Interval" connection mode) and the monitoring is active, then the LED is switched off. If the last connection 
establishment was successful and the [rapidM2M M3](https://www.microtronics.com/en/products/rapidM2M_M3.html) is waiting for the next contact with the Cloud Server (e.g. during "Interval" connection mode) but 
the monitoring is stopped, then the LED lights up yellow. 

A connection to the Cloud Server is either triggered automatically by the device following 
expiry of the transmission interval or receipt of a wakeup SMS or manually by pressing the button briefly (< 3sec.) as already mentioned. When 
the transmission interval expires the values of the 3 counters are recorded so that the current counter readings are visible on the Cloud Server 
after establishing the connection 


>**Note:** The units specified in the following relate to the exchange of data between the rapidM2M M3 and Cloud Server. When defining the connector, 
the "vscale" attribute can be used to adapt the units for the display on the interface of the Cloud Server or output via the REST-API. The 
transmission interval for the display/input is thus converted from seconds to minutes, for example.



The script generates and transmits the following measurement values:

|Measurement value:  |   Unit:   |    Explanation: |
|----|----|----|
|Player1 counter    |     ---     |    Number of goals shot by Player1. |
|Player2 counter    |     ---     |    Number of goals shot by Player2. |
|Difference     |         ---     |    Difference between Player2 and Player1 counter (Player2 counter - Player1 counter) |


The script provides the following configuration options:

|Parameter: |                          Unit: |   Explanation: |
|----|----|----|
|Transmission interval|               sec.  |  Time between transmissions|
| Connection type                   | ---   | 0: The device connects in the transmission cycle.</br> 1: The device connects in the transmission cycle.However, a connection can also be initiated through the server. </br> 2: The device does not disconnect the connection and continuously transmits the measurement data. |
