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
 * Simple "Indicating the transmission state" Example
 *
 * Initiates a connection to the server and uses LED to indicate the current connection state
 * LED is off 	if the device is offline (not connected) or in "Wakeup" mode
 * LED is on    if the device is connected to the server 
 * LED flickers if the connection establishment has started or the device is waiting for the next automatic retry
 * LED blinks 	if the connection establishment has failed
 * 
 * Only compatible with rapidM2M M3
 * 
 * @version 20190723
 */

/* Path for hardware-specific include file */
#include ".\rapidM2M IoT-Box\iotbox.inc"

/*
 * TX_STATE STARTED     Flicker
 * TX_STATE RETRY       Flicker
 * TX_STATE ACTIVE      Constantly on
 * TX_STATE WAKEUPABLE  Off
 * TX_STATE NONE        Off
 * TX_STATE FAILED      Blink
 */

/* Forward declarations of public functions */
forward public Timer1s();                   // Called up 1x per sec. for the program sequence


/* Application entry point */
main()
{
 /* Temporary memory for the index of a public function and the return value of a function  */
  new iIdx, iResult;

  printf("Led Demo\r\n");                   // Issues the name of the example via the console

  /* Initialisation of a 1 sec. timer used for the general program sequence
     - Determining the function index that should be executed 1x per sec.
     - Transferring the index to the system
	   - In case of a problem the index and return value of the init function are issued by the console  */
  iIdx = funcidx("Timer1s");
  iResult = rM2M_TimerAdd(iIdx);
  if(iResult < OK)
    printf("rM2M_TimerAdd(%d) = %d\r\n", iIdx, iResult);
  
  /* Initialisation of the LED -> control via script activated */ 
  iResult = Led_Init(LED_MODE_SCRIPT);
  printf("Led_Init() = %d\r\n", iResult);
  
  Led_Off();                                // Switches off LED

  rM2M_TxSetMode(RM2M_TXMODE_TRIG);         // Sets the connection type to "Interval" mode  
  rM2M_TxStart();                           // Initiates a connection to the server  
}

/* 1 sec. timer is used for the general program sequence */
public Timer1s()
{
  new iTxState;                             // Temporary memory for the current connection status
  static iTxStateAkt;                       // Last determined connection status 
  
  iTxState = rM2M_TxGetStatus();            // Gets the current connection status
  if(iTxState != iTxStateAkt)               // If the connection status has changed ->  
  {
    if(iTxState == 0)                       // If the connection is not active, has not started and is not waiting for next automatic retry 
    {
      print("iTxState: ---\r\n");
      Led_Off();                            // Switches off LED
    }
    else                                    // Otherwise ->
    {
      print("iTxState: ");
      if(iTxState & RM2M_TX_FAILED)         // If the connection establishment failed ->
      {
        print("FAILED | ");
        // Red LED should blink
        Led_Off();
        Led_Blink(0, 0xFF0000);
      }
      if(iTxState & RM2M_TX_ACTIVE)         // If the GPRS connection is established ->
      {
        print("ACTIVE | ");
        // Green LED should be on
        Led_Off();
        Led_On(0x00FF00);
      }
      if(iTxState & RM2M_TX_STARTED)        // If the connection establishment has started ->
      {
        print("STARTED | ");
        // Green LED should flicker	
        Led_Off();
        Led_Flicker(0, 0x00FF00);
      }
      if(iTxState & RM2M_TX_RETRY)          // If the system is waiting for the next automatic retry
      {
        print("RETRY | ");
        // Green LED should flicker	
        Led_Off();
        Led_Flicker(0, 0x00FF00);
      }
      // If the modem is logged into the GSM network AND (the connection is not active, has not started and is not waiting for next automatic retry) ->
      if((iTxState & RM2M_TX_WAKEUPABLE) && !(iTxState & (RM2M_TX_RETRY + RM2M_TX_STARTED + RM2M_TX_ACTIVE)))
      {
        print("WAKEUPABLE | ");
        Led_Off();                          // Switches off LED		
      }
      print("\r\n");
    }
    iTxStateAkt = iTxState;                 // Copies current connection status to the variable for the last determined connection status 
  }
}

