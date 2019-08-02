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
 * Simple "LED and Button" Example
 *
 * As long as the button is pressed, the LED lights up white. If the button is released, 
 * the LED is turned off.
 * 
 * Only compatible with rapidM2M M3 
 * Special hardware circuit necessary 
 * 
 * @version 20190624 
 */
 
/* Path for hardware-specific include file */
#include ".\rapidM2M IoT-Box\iotbox"

/* Forward declarations of public functions */
forward public KeyChanged(iState);       // Called up when the button is pressed or released

/* Application entry point */
main()
{
  /* Temporary memory for the index of a public function and the return value of a function             */
  new iIdx, iResult;

  printf("Led Demo\r\n");          // Issues the name of the example via the console 

  /* Initialisation of the button -> Evaluation by the script activated
     - Determining the function index that should be called up when pressing or releasing the button
     - Transferring the index to the system and informing it that the button is controlled by the script
     - Index and return value of the init function are issued by the console                            */
  iIdx = funcidx("KeyChanged");                        
  iResult = Switch_Init(SWITCH_MODE_SCRIPT, iIdx);     
  printf("Switch_Init(%d) = %d\r\n", iIdx, iResult); 

  /* Initialisation of the LED -> Control via script activated */ 
  iResult = Led_Init(LED_MODE_SCRIPT);
  printf("Led_Init() = %d\r\n", iResult);
  
  Led_Off();                               // Switches off LED
}

/**
 * Function that should be called up when the button is pressed or released
 *
 * @param iState:s32 - Signal level
 *					   0: Button released
 *                     1: Button pressed
 */
public KeyChanged(iState)
{
  if(iState)                               // If the button is pressed 
  {
    Led_On(0xFFFFFF);                      // Turns on the LED (colour: white)
  }
  else                                     // Otherwise -> the button is released
  {
    Led_Off();                             // Switches off LED
  }
}