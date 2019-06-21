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
 * Simple "Button" Example
 *
 * Evaluates the state of the button
 * If the button was pressed, "[KEY] Key pressed" is issued via the console.
 * If the button was released, "[KEY] Key released" is issued via the console. 
 * 
 * Only compatible with rapidM2M M3
 * 
 * @version 20190618  
 */

 /* Path for hardware-specific include file */
#include ".\rapidM2M IoT-Box\iotbox"

/* Forward declarations of public functions */
forward public KeyChanged(iKeyState);       // Called up when the button is pressed or released

/* Application entry point */
main()
{
  /* Temporary memory for the index of a public function and the return value of a function             */
  new iIdx;
  new iResult;

  /* Initialisation of the button -> evaluation by the script activated
     - Determining the function index that should be called up when pressing or releasing the button
     - Transferring the index to the system and informing it that the button is controlled by the script
     - Index and return value of the init function are issued by the console                            */
  iIdx = funcidx("KeyChanged");                        
  iResult = Switch_Init(SWITCH_MODE_SCRIPT, iIdx);     
  printf("Switch_Init(%d) = %d\r\n", iIdx, iResult); 
}

/**
 * Function that should be called up when the button is pressed or released
 *
 * @param iKeyState:s32 - Signal level
 *						  0: Button released
 *                        1: Button pressed
 */
public KeyChanged(iKeyState)
{
  if(!iKeyState)                      // If the button was released ->
  {
    printf("[KEY] Key released\r\n"); // Prints "[KEY] Key released" to the console
  }
  else                                // Otherwise -> if the button was pressed ->
  {
    printf("[KEY] Key pressed\r\n");  // Prints "[KEY] Key pressed" to the console
  }
}
