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
 * Extended "LED and GPIO (ext. button)" Example
 *
 * Changes the colour and mode of the RGB LED each time the external button connected to GPIO2 is pressed.
 * 
 * The following sequence arises: Off - Red flashing - Green blinking - Blue flickering - White on
 *
 * Note: The external button must be placed between GPIO and ground. Furthermore, a pullup between the GPIO and 2V8 out is required.
 * 
 * Only compatible with rapidM2M M3
 * Special hardware circuit necessary 
 * 
 * @version 20190619  
 */
 
/* Path for hardware-specific include file */
#include ".\rapidM2M IoT-Box\iotbox"

/* forward declarations of public functions */
forward public Timer100ms();                     // Called up every 100ms to check the current state of the GPIO and control the LED

/* Pin configuration */
const
{
  GPIO_BUTTON = GPIO_2, 		                 // The external button is connected to GPIO2  
}

/* application entry point */
main()
{
  /* Temporary memory for the index of a public function and the return value of a function             */
  new iIdx, iResult;

  printf("Led Demo\r\n");                        // Issues the name of the example via the console 

  /* Initialisation of a 100ms timer used to check the current state of the GPIO and control the LED
     - Determining the function index that should be executed every 100ms
     - Transferring the index to the system and informing it that the timer should be restarted 
	   following expiry of the interval
     - Index and return value of the init function are issued by the console                            */   
  iIdx = funcidx("Timer100ms");
  iResult = rM2M_TimerAddExt(iIdx, true, 100);
  printf("rM2M_TimerAddExt(%d) = %d\r\n", iIdx, iResult);

  /* Initialisation of the LED -> control via script activated */ 
  iResult = Led_Init(LED_MODE_SCRIPT);
  printf("Led_Init() = %d\r\n", iResult);
  
  Led_Off();                                     // Switches off LED
  
  rM2M_GpioDir(GPIO_BUTTON, RM2M_GPIO_INPUT);    // Sets the signal direction for the GPIO connected to external button to input 
}

/* 100ms timer used to check the current state of the GPIO and control the LED */
public Timer100ms()
{
  static iLed;                                   // Current state of LED (0 =^ off; 1 =^ red flashing, 2 ^= green blinking, 3 ^= blue flickering, 4 ^= white on)
  static iStatePrev;                             // Last determined state of the GPIO
  new iState;                                    // Temporary memory for the current state of the GPIO
  
  iState = rM2M_GpioGet(GPIO_BUTTON);            // Reads the signal level at the GPIO (0 =^ "low" signal level, 1 =^ "high" signal level) 
												 // Button has an inverted logic (0 =^ pressed,  1 ^= not released)
  
  // If the GPIO state has changed and the button is currently pressed ->												 
  if((iState != iStatePrev) && !iState) 
  {
    iLed = (iLed + 1) % 5;                       // Increases counter for the LED state. It is ensured that the counter reading does not exceed 4.
    printf("Led-State: %d\r\n", iLed);           // Issues newly determined LED state via the console
    
    
    switch(iLed)                                 // Switches the newly determined LED state ->
    {
      case 0:
        Led_Off();                               // Turns off LED
      case 1:
        Led_Flash(0, 0xFF0000);                  // Makes the LED flash red
      case 2:
        Led_Blink(0, 0x00FF00);                  // Makes the LED blink green
      case 3:
        Led_Flicker(0, 0x0000FF);                // Makes the LED flicker blue
      case 4: 
        Led_On(0xFFFFFF);                        // Makes the LED light up white
    }
  }
  iStatePrev = iState;                           // Copies current GPIO status to the variable for the last determined GPIO status 
}
