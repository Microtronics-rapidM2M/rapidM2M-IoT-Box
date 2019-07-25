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
 * Simple "LED and GPIO (ext. button)" Example
 *
 * As long as the external button connected to GPIO2 is pressed, the LED lights up white. If the external button is released, 
 * the LED is turned off.
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

/* Application entry point */
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
  new iState;                                    // Temporary memory for the current state of the GPIO
  
  iState = rM2M_GpioGet(GPIO_BUTTON);            // Reads the signal level at the GPIO (0 =^ "low" signal level, 1 =^ "high" signal level) 
  iState = !iState; 							 // Button has an inverted logic (0 =^ pressed,  1 ^= not released)
  
  if(iState)                                     // If the button is pressed  ->
  {
    Led_On(0xFFFFFF);                            // Turns on the LED (colour: white)
  }
  else                                           // Otherwise -> button is released 
  {
    Led_Off();                                   // Switches off LED
  }
}
