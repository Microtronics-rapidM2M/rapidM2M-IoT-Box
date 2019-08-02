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
 * "RGB LED" Example V2
 *
 * Changes the color of the RGB LED each second. To do this, a counter is repeatedly increased 
 * from 0 to 7. Each bit of the counter is assigned a color of the RGB LED.
 *
 * Bit0 = Red
 * Bit1 = Green
 * Bit2 = Blue
 *
 * This results in the following color sequence: Off - Red - Green - Yellow - Blue - Magenta - Cyan - White
 *
 * Only compatible with rapidM2M M3
 * Special hardware circuit necessary
 *
 * @version 20190624  
 */

/* Path for hardware-specific include file */
#include ".\rapidM2M IoT-Box\iotbox"

/* Specifies which bit is assigned to the individual colors of the RGB LED */
const
{
  LED_R = 0,                                //Bit that is assigned to the red color of the RGB LED   (0^=Off; 1=^On)
  LED_G = 1,                                //Bit that is assigned to the green color of the RGB LED (0^=Off; 1=^On)
  LED_B = 2,                                //Bit that is assigned to the blue color of the RGB LED  (0^=Off; 1=^On)
}

/* Forward declarations of public functions */
forward public MainTimer();                 // Called up 1x per sec. for the program sequence

/* Global variable declarations */
static iLedState;                           // Current LED state (counts from 0 to 7)
static iColor;                              // Current color configuration

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

  /* Initialisation of the LED -> Control via script activated */ 
  iResult = Led_Init(LED_MODE_SCRIPT);
  printf("Led_Init() = %d\r\n", iResult);
  
  Led_Off();                                   // Switches off LED
}

/* 1 sec. timer is used for the general program sequence */
public MainTimer()
{
  printf("[LED] State: %d\r\n", iLedState);    // Issues the current LED state via the console
  
  /* Shifts the content of the variable holding the LED status so that the bit assigned to the 
     respective colour is at position 0 (bit0). This is followed by an "and" conjunction with the 
	 value "1". If the result is 0, the respective colour is switched off. If the result is 1, 
	 the respective colour is switched on.                                                      */
	 
  if((iLedState >> LED_R) & 1)  // Red colour of the RGB LED
    iColor = iColor | 0xFF0000; // Sets colour to red
  else
    iColor = iColor &~0xFF0000; // Clears red colour
  
  if((iLedState >> LED_G) & 1)  // Green colour of the RGB LED
    iColor = iColor | 0x00FF00; // Sets colour to green
  else
    iColor = iColor &~0x00FF00; // Clears green colour

  if((iLedState >> LED_B) & 1)  // Blue colour of the RGB LED
    iColor = iColor | 0x0000FF; // Sets colour to blue
  else
    iColor = iColor &~0x0000FF; // Clears blue colour
  
  Led_On(iColor);                              // Turns on RGB LED with configured colour
  
  // Increases counter for the LED state. It is ensured that the counter reading does not exceed 7.
  iLedState = (iLedState + 1) & (0x07);
}

