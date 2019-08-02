/*
 *                  _     _  __  __ ___  __  __
 *                 (_)   | ||  \/  |__ \|  \/  |
 *  _ __ __ _ _ __  _  __| || \  / |  ) | \  / |
 * | '__/ _` | '_ \| |/ _` || |\/| | / /| |\/| |
 * | | | (_| | |_) | | (_| || |  | |/ /_| |  | |
 * |_|  \__,_| .__/|_|\__,_||_|  |_|____|_|  |_|
 *           | |
 *           |_|
 *
 * Extended "State machine" example
 *
 * The state machine has seven different states that are indicated by the status LED:
 * - STATE_OFF               status LED is off for 1 sec.
 * - STATE_RED               status LED lights up red for 5 sec.
 * - STATE_RED_YELLOW        status LED lights up yellow for 2 sec.
 * - STATE_GREEN             status LED lights up green for 5 sec.
 * - TIMEOUT_GREEN_BLINKING  status LED blinks green for 3 sec. (ton=1sec. toff=1sec.)
 * - STATE_YELLOW            status LED lights up yellow for 2 sec.
 *
 * When turned on, the state machine is in state "STATE_OFF" for one sec. 
 * Then it switches to state "STATE_RED" for 5 seconds.
 * Then it switches to state "STATE_RED_YELLOW" for 2 seconds.
 * Then it switches to state "STATE_GREEN" for 5 seconds.
 * Then it switches to state "TIMEOUT_GREEN_BLINKING" for 3 seconds.
 * Then it switches to state "STATE_YELLOW" for 2 seconds.
 * After that, the sequence just described is continuously repeated starting with the state "STATE_RED".
 * 
 * Note: The state "STATE_OFF" is only used once at the PowerOn.
 *
 * Only compatible with rapidM2M M3
 *
 * @version 20190704
 */

/* Path for hardware-specific include file */
#include ".\rapidM2M IoT-Box\iotbox"

/* Forward declarations of public functions */
forward public TimerMain();                 // Called up 1x per sec. for the program sequence

// RGB hex color codes
const
{
  COLOR_RED     = 0xFF0000,
  COLOR_YELLOW  = 0xFFFF00,
  COLOR_ORANGE  = 0xFF8C00,
  COLOR_GREEN   = 0x00FF00,
}

// Possible states for the application 
const
{
  STATE_OFF = 0,
  STATE_RED,
  STATE_RED_YELLOW,
  STATE_GREEN,
  STATE_GREEN_BLINKING,
  STATE_YELLOW,
}

// Delay before switching to the next state [sec.]
const
{
  TIMEOUT_OFF              = 1,
  TIMEOUT_RED              = 5,
  TIMEOUT_RED_YELLOW       = 2,
  TIMEOUT_GREEN            = 5,
  TIMEOUT_GREEN_BLINKING   = 3,
  TIMEOUT_YELLOW           = 2,
}

static iAppState;                           // Current state of the application
static iTimerTimeout;                       // Remaining time until switching to the next state

/* Application entry point */
main()
{
  /* Temporary memory for the index of a public function and the return value of a function  */
  new iIdx, iResult;

  /* Initialisation of the LED -> Control via script activated */
  iResult = Led_Init(LED_MODE_SCRIPT);
  printf("Led_Init() = %d\r\n", iResult);
  
  Led_Off();

  /* Initialisation of a 1 sec. timer used for the general program sequence
     - Determining the function index that should be executed 1x per sec.
     - Transferring the index to the system
     - In case of a problem the index and return value of the init function are issued by the console  */
  iIdx = funcidx("TimerMain");
  iResult = rM2M_TimerAdd(iIdx);
  printf("rM2M_TimerAdd(%d) = %d\r\n", iIdx, iResult);
  
  // Init state
  StateChange(STATE_OFF);                      // Calls function to set the state of the application to "STATE_OFF"
}

 /**
 * Changes the state of the application
 *
 * @param iNewState:s32    - New state for the application 
 */
StateChange(iNewState)
{
  switch(iNewState)                            // Switch new state for the application
  {
    case STATE_OFF:
    {
      // Turns off status LED
      Led_Off();
      
      // Sets the counter for the remaining time until switching to the next state to "TIMEOUT_OFF"
      Handle_CheckWait(iTimerTimeout, TIMEOUT_OFF);
    }
    case STATE_RED:
    {
      // Status LED should light up red
      Led_On(COLOR_RED);
      
      // Sets the counter for the remaining time until switching to the next state to "TIMEOUT_RED"
      Handle_CheckWait(iTimerTimeout, TIMEOUT_RED);
    }
    case STATE_RED_YELLOW:
    {
      // Status LED should light up orange
      Led_On(COLOR_ORANGE);
      
      // Sets the counter for the remaining time until switching to the next state to "TIMEOUT_RED_YELLOW"
      Handle_CheckWait(iTimerTimeout, TIMEOUT_RED_YELLOW);
    }
    case STATE_GREEN:
    {
      // Status LED should light up green
      Led_On(COLOR_GREEN);
      
      // Sets the counter for the remaining time until switching to the next state to "TIMEOUT_GREEN"
      Handle_CheckWait(iTimerTimeout, TIMEOUT_GREEN);
    }
    case STATE_GREEN_BLINKING:
    {
      // Status LED should blink green
      Led_Off();
      Led_Blink(0, COLOR_GREEN);
      
      // Sets the counter for the remaining time until switching to the next state to "TIMEOUT_GREEN"
      Handle_CheckWait(iTimerTimeout, TIMEOUT_GREEN_BLINKING);
    }
    case STATE_YELLOW:
    {
      // Status LED should light up yellow
      Led_On(COLOR_YELLOW);
      
      // Sets the counter for the remaining time until switching to the next state to "TIMEOUT_YELLOW"
      Handle_CheckWait(iTimerTimeout, TIMEOUT_YELLOW);
    }
  }
  
  iAppState = iNewState;                       // Copies the new state to the variable for the current state of the application
}

/* Function that manages the switching between the different application states */ 
StateHandle()
{
  switch(iAppState)                            // Switch current state of the application
  {
    case STATE_OFF:
    {
      if(Handle_CheckWait(iTimerTimeout))      // If the remaining time until switching to the next state has expired ->  
        StateChange(STATE_RED);                // Calls function to set the state of the application to "STATE_RED"
    }
    case STATE_RED:
    {
      if(Handle_CheckWait(iTimerTimeout))      // If the remaining time until switching to the next state has expired ->
        StateChange(STATE_RED_YELLOW);         // Calls function to set the state of the application to "STATE_RED_YELLOW"
    }
    case STATE_RED_YELLOW:
    {
      if(Handle_CheckWait(iTimerTimeout))      // If the remaining time until switching to the next state has expired ->
        StateChange(STATE_GREEN);              // Calls function to set the state of the application to "STATE_GREEN"
    }
    case STATE_GREEN:
    {
      if(Handle_CheckWait(iTimerTimeout))      // If the remaining time until switching to the next state has expired ->
        StateChange(STATE_GREEN_BLINKING);     // Calls function to set the state of the application to "STATE_GREEN_BLINKING"
    }
    case STATE_GREEN_BLINKING:
    {
      if(Handle_CheckWait(iTimerTimeout))      // If the remaining time until switching to the next state has expired ->
        StateChange(STATE_YELLOW);             // Calls function to set the state of the application to "STATE_YELLOW" 
    }
    case STATE_YELLOW:
    {
      if(Handle_CheckWait(iTimerTimeout))      // If the remaining time until switching to the next state has expired ->
        StateChange(STATE_RED);                // Calls function to set the state of the application to "STATE_RED"
    }
  }
}

/**
 * Checks whether the remaining time until switching to the next state has expired.
 *
 * If the value for "iReset" (new remaining time until switching to the next state) is not 0, the transferred counter containing 
 * the remaining time until switching to the next state is set to "iReset". The return value is set to "False"
 *
 * If the value for "iReset" is 0, the transferred counter containing the remaining time until switching to the 
 * next state is decremented. If the time has expired, the return value is set to "True", otherwise it is set to "False"
 * 
 * Note: Parameter "iTimer" is transferred as a reference. This means that changes to the value within 
 *       the function have an impact on the variable outside the function.
 *
 *
 * @param iTimer:s32 - Counter containing the remaining time until switching to the next state
 * @param iReset:s32 - New remaining time until switching to the next state (- OPTIONAL)
 * @return s32       - False: Time has NOT expired
 *                     True:  Time has expired 
 */
Handle_CheckWait(&iTimer, iReset=0)
{
  new iResult = false;                         // Temporary memory for the return value of the function is set to "False"
  
  if(iReset)                                   // If the transferred counter containing the remaining time should be set to a new value ->
  {
    iTimer = iReset;                           // Sets the counter containing the remaining time to the new value   
  }
  else if(iTimer > 0)                          // If the counter containing the remaining time has not expired ->
  {
    iTimer--;                                  // Decrements the counter containing the remaining time until switching to the next state
    if(iTimer == 0)                            // If the counter containing the remaining time has expired ->
    {
      iResult = true;                          // Sets the return value of the function to "True" 
    }
  }
  return iResult;                              // Return  
}

/* 1 sec. timer is used for the general program sequence */
public TimerMain()
{
  StateHandle();                               // Manages the switching between the different application states
}


