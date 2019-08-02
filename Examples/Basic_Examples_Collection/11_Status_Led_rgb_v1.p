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
 * "RGB LED" Example V1
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

/* Bit mask for the LED state */
const
{
  LED1_R_MSK = 0x01,                        // Bit indicating the state of the red part of the RGB LED   (0=^Off; 1=^On)
  LED1_G_MSK = 0x02,                        // Bit indicating the state of the green part of the RGB LED (0=^Off; 1=^On)
  LED1_B_MSK = 0x04,                        // Bit indicating the state of the blue part of the RGB LED  (0=^Off; 1=^On)
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
  
  if(iLedState & LED1_R_MSK)                   // If the bit for the red part of the RGB LED is set ->
  {
    iColor = iColor | 0xFF0000;                // Turns on red part of the RGB LED	
  }
  else                                         // Otherwise (bit not set) ->
  {
    iColor = iColor &~0xFF0000;                // Turns off red part of the RGB LED	
  }

  if(iLedState & LED1_G_MSK)                   // If the bit for the green part of the RGB LED is set ->
  {
    iColor = iColor | 0x00FF00;                // Turns on green part of the RGB LED	
  }
  else                                         // Otherwise (bit not set) ->
  {
    iColor = iColor &~0x00FF00;                // Turns off green part of the RGB LED	
  }

  if(iLedState & LED1_B_MSK)                   // If the bit for the blue part of the RGB LED is set ->
  {
    iColor = iColor | 0x0000FF;                // Turns on blue part of the RGB LED	
  }
  else                                         // Otherwise (bit not set) ->
  {
    iColor = iColor &~0x0000FF;                // Turns off blue part of the RGB LED
  }  
  
  Led_On(iColor);                              // Turns on RGB LED with configured colour
  
  // Increases counter for the LED state. It is ensured that the counter reading does not exceed 7.
  iLedState = (iLedState + 1) & (LED1_R_MSK|LED1_G_MSK|LED1_B_MSK);
}

