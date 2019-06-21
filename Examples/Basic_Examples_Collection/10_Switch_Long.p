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
 * Extended "Button" Example
 *
 * Evaluates the state of the button and also detects if the button was pressed only briefly or for a longer
 * time
 *
 * If the button was pressed, "[KEY] Key pressed" is issued via the console.
 * If the button was pressed and held for a longer time, "[KEY] Long Push Detected" is issued via the console.
 * If the button was released after it had been pressed and held for a longer time, "[KEY] Long key detected 
 * and key released" is issued via the console.
 * If the button was released after it had been pressed briefly, "[KEY] Key released" is issued via the
 * console.
 * 
 * Only compatible with rapidM2M IoT-Box, myDatalogEASYv3 and BLE Gateway
 *
 * @version 20190619  
 */

/* Path for hardware-specific include file */
#include ".\rapidM2M IoT-Box\iotbox"

/* Forward declarations of public functions */
forward public KeyChanged(iKeyState);       // Called up when the button is pressed or released
forward public KeyDetectLong();             // Called up when the timer to detect a long key press has
                                            // expired

const
{
  CNT_LONG_PUSH_TIME = 5000,                // Time (ms) for which the button must be pressed to detect
                                            // a long button press
}

/* Global variable declarations */
static iLongPushDetected;                   // Long key press detected

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
  /* Temporary memory for the index of a public function and the return value of a function             */   
  new iIdx,iResult;
  
  if(!iKeyState)                            // If the button was released ->
  {
    if(iLongPushDetected)                   // If the button had been pressed for a long time ->
    {
      // Prints "[KEY] Long key detected and key released" to the console
      printf("[KEY] Long key detected and key released\r\n");  
	  
      iLongPushDetected = 0;                // Deletes "long key press detected" flag
    }
    else                                    // Otherwise (i.e. the button was pressed only briefly) ->
    {
     /* Deletes the timer for long keystroke detection if the button has been pressed only for a short
         time, so that it cannot expire and therefore the "long key press detected" flag is not set.
         - Determining the function index that should be called up when the timer expires
         - Transferring the index to the system so that the timer can be deleted
         - If it was not possible to delete the timer -> Index and TimerRemove function return values
           are issued via the console                                                                   */
      iIdx = funcidx("KeyDetectLong");
      iResult = rM2M_TimerRemoveExt(iIdx);
      if(iResult != OK) 
        printf("[KEY] rM2M_TimerRemove(%d) = %d\r\n", iIdx, iResult);
        
      printf("[KEY] Key released\r\n");     // Prints "[KEY] Key released" to the console
    }
  }
  else                                      // Otherwise -> if the button was pressed ->
  {
    /* Starts a timer for the purpose of detecting a long key press. If the timer expires, a
     flag is set by the function transferred.
    - Determining the function index that should be called up when the timer expires and informing it 
	  that the timer should be stopped following expiry of the interval (single shot timer)
    - Transferring the index to the system                                                              */    
    iIdx = funcidx("KeyDetectLong");
    rM2M_TimerAddExt(iIdx, false, CNT_LONG_PUSH_TIME);
    
    printf("[KEY] Key pressed\r\n");        // Prints "[KEY] Key pressed" to the console
  } 
}

/* Function that is called when the timer to detect a long key press has expired  */
public KeyDetectLong()
{
  print("[KEY] Long Push Detected\r\n");    // Issues the detection of a long key press via the console
  iLongPushDetected = 1;                    // Sets "long key press detected" flag
}

