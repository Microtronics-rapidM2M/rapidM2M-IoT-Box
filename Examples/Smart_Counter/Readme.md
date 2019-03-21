
# Example - Smart Stadium
![Smart Stadium Image](https://blog.microtronics.at/wp-content/uploads/2018/01/smart-stadium-come-go.jpg)

The script gathers pulses of signal sensors via the two universal inputs. For correct detection, these must have a duration of at least 10ms. 

Periodically, the counter readings for the two universal inputs are calculated separately and then their difference (UI1-UI2) is determined. When calculating the counter reading for a universal input, the number of newly detected pulses is multiplied by the configurable impulse value and the result is then added to the previous counter reading. The pulses value can be configured independently for each of the two universal inputs. 

The measurement data generated in this way are recorded periodically and transmitted to the Cloud server. The interval for recording and transmitting measurement data can be configured. The connection type can also be configured. 

If the "online" connection type is selected, the measurement data is transmitted to the server as soon as the measurement data is created. The input counter "IN" (UI1), the output counter "OUT" (UI2) and the difference "Energy used" (UI1-UI2) are recorded. 

The current operating state is indicated by the RGB-LED. The LED lights up magenta if there is an existing connection with the Cloud server. The LED flickers 
magenta while the connection is being established. If the last connection attempt failed, the LED flashes red until the next attempt to establish a connection. However, if the last connection establishment was successful and the rapidM2M M3 is waiting for the next contact with the Cloud server (e.g. during "Interval" connection mode), then the LED is switched off. 

A connection to the server is either triggered automatically by the device following expiry of the transmission interval or receipt of a wakeup SMS or manually by pressing the button briefly (< 3sec.). By pressing the button for a long time (>3sec.) all 3 counter readings  (UI1, UI2 and difference) are reset.

> **Note:** The units specified in the following relate to the exchange of data between the rapidM2M M3 and Cloud server. When defining the connector, the "vscale" attribute can be used to adapt the units for the display on the interface of the Cloud server or output via the REST-API. The transmission interval for the display/input is thus converted from seconds to minutes, for example.



The script generates and transmits the following measurement values:

| Measurement value:   |   Unit:  |       Explanation:  |
|---------------------|--------|-----------------------|
|Input counter  |         ---  | Sum of the added weighted impulses at the UI1. Calculation: current counter reading + (newly detected pulses * impulse value) |
|Output counter |         ---  | Sum of the added weighted impulses at the UI2. Calculation: current counter reading + (newly detected pulses * impulse value) |
|Difference     |        ---   | Difference between input and output counter (input counter - output counter)|


The script provides the following configuration options:

|Parameter:				| Unit:   |   Explanation:							|
|-----------------------|---------|-----------------------------------------|
|Record interval        |  sec.   | Time between measurement data recordings|
|Transmission interval  |  sec.   | Time between transmissions				|
|Connection type       	|  ---    |<li> 0: The device connects in the transmission cycle.</li> <li> 1: The device connects in the transmission cycle.However, a connection can also be initiated through the server. </li> <li> 2: The device does not disconnect the connection and continuously transmits the measurement data.</li> |
|                       |         |                                         |  
|Pulse value of the input counter |  ---    | Factor with which the newly detected pulses are multiplied before they are added up |
|Pulse value of the output counter |  ---    | Factor with which the newly detected pulses are multiplied before they are added up|


Further Information: https://blog.microtronics.at/smart-counting-no-problem