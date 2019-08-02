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
 * Extended "LED and Button" Example
 *
 * Changes the colour and mode of the RGB LED each time the button is pressed.
 * 
 * The following sequence arises: Off - Red flashing - Green blinking - Blue flickering - White on
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

  printf("Led Demo\r\n");     // Issues the name of the example via the console 

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
  
  Led_Off();     // Switches off LED
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
  static iLed;                         // Current state of LED (0 =^ off; 1 =^ red flashing, 2 ^= green blinking, 3 ^= blue flickering, 4 ^= white on)

  if(iState)                           // If the button is pressed 
  {
    iLed = (iLed + 1) % 5;             // Increases counter for the LED state. It is ensured that the counter reading does not exceed 4.
    printf("Led-State: %d\r\n", iLed); // Issues newly determined LED state via the console
    
    switch(iLed)                       // Switches the newly determined LED state ->
    {
      case 0:
        Led_Off();                     // Turns off LED
      case 1:
        Led_Flash(0, 0xFF0000);        // Makes the LED flash red
      case 2:
        Led_Blink(0, 0x00FF00);        // Makes the LED blink green
      case 3:
        Led_Flicker(0, 0x0000FF);      // Makes the LED flicker blue
      case 4: 
        Led_On(0xFFFFFF);              // Makes the LED light up white
    }
  }
}