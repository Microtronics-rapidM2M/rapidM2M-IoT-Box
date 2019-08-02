/**
 *                  _     _  __  __ ___  __  __
 *                 (_)   | ||  \/  |__ \|  \/  |
 *  _ __ __ _ _ __  _  __| || \  / |  ) | \  / |
 * | '__/ _` | '_ \| |/ _` || |\/| | / /| |\/| |
 * | | | (_| | |_) | | (_| || |  | |/ /_| |  | |
 * |_|  \__,_| .__/|_|\__,_||_|  |_|____|_|  |_|
 *           | |
 *           |_|
 *
 * Extended "LED" Example
 *
 * Toggles external LED2 (GPIO2) and external LED3 (GPIO3) every second.
 * If external LED2 is on, then external LED3 is off and vice versa.
 * 
 * Only compatible with rapidM2M M3
 * Special hardware circuit necessary
 *
 * @version 20190701
 */

/* Path for hardware-specific include file */
#include ".\rapidM2M IoT-Box\iotbox"

/* Pin configuration */
const
{
  PIN_LED2    = GPIO_2,                     // External LED2 (GPIO2)
  PIN_LED3    = GPIO_3,                     // External LED3 (GPIO3)
  
  LED_ENABLE  = RM2M_GPIO_HIGH,             // By setting the GPIO to "high" the external LED is turned on
  LED_DISABLE = RM2M_GPIO_LOW,              // By setting the GPIO to "low" the external LED is turned off
};


/* Forward declarations of public functions */
forward public MainTimer();                 // Called up 1x per sec. for the program sequence

/* Global variables declarations */
static iLedState;                           // Current LED state (1=^ external LED2 "On" and external LED3 "Off"
                                            //                    x=^ external LED2 "Off" and external LED3 "On")

/* Application entry point */
main()
{
 /* Temporary memory for the index of a public function and the return value of a function  */
  new iIdx, iResult;
  
  /* Initialisation of a 1 sec. timer used for the general program sequence
     - Determining the function index that should be executed 1x per sec.
     - Transferring the index to the system
	 - In case of a problem the index and return value of the init function are issued by the console  */
  iIdx = funcidx("MainTimer");	
  iResult = rM2M_TimerAdd(iIdx);
  if(iResult < OK)
    printf("rM2M_TimerAddExt(%d) = %d\r\n", iIdx, iResult);
  
  /* Sets signal direction for GPIO2 and GPIO3 used to control the external LED2 and external LED3 to "Output" */
  /* Note: It is recommended to set the desired output level of a GPIO before setting the 
           signal direction for the GPIO.                                                     */
  rM2M_GpioSet(PIN_LED2, LED_DISABLE);      // Sets the output level of GPIO2 to "low" (external LED2 is off)
  rM2M_GpioDir(PIN_LED2, RM2M_GPIO_OUTPUT); // Sets the signal direction of GPIO2 used to control the external LED2
  rM2M_GpioSet(PIN_LED3, LED_DISABLE);      // Sets the output level of GPIO3 to "low" (external LED3 is off)
  rM2M_GpioDir(PIN_LED3, RM2M_GPIO_OUTPUT); // Sets the signal direction of GPIO3 used to control the external LED3
}

/* 1 sec. timer is used for the general program sequence */
public MainTimer()
{   
  if(iLedState)                             // If external LED2 is currently "On" and external LED3 is currently "Off" ->  
  { 
    rM2M_GpioSet(PIN_LED2, LED_DISABLE);    // Turns off external LED2
    rM2M_GpioSet(PIN_LED3, LED_ENABLE);     // Turns on external LED3
    printf("[LED] 2:off 3:on\r\n");
  }
  else                                      // Otherwise (i.e. external LED2 "Off" and external LED3 "On")
  { 
    rM2M_GpioSet(PIN_LED2, LED_ENABLE);     // Turns on external LED2
    rM2M_GpioSet(PIN_LED3, LED_DISABLE);    // Turns off external LED3
    printf("[LED] 2:on 3:off\r\n");
  }
  
  iLedState = !iLedState;                   // Toggles the variable which holds the current LED state
}
