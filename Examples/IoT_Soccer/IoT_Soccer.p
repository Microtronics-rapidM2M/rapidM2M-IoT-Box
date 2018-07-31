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
 */

/* Path for hardware-specific include file */
#include ".\rapidM2M IoT-Box\iotbox"


/* Forward declarations of the public functions */
forward public Timer1s();                   // called up 1x per sec. for the program sequence
forward public Timer_ms();                  // ms Timer for polling the counter inputs
forward public ReadConfig(cfg);             // called up when one of the config blocks is changed
forward public KeyChanged(iKeyState);       // called up when the button is pressed or released
forward public LongPushDetect();            // called up when the timer to detect a long key press has
                                            // expired

/* Standard values to initialise the configuration */
const
{
  ITV_TRANSMISSION   = 1 * 60 * 60,         // Transmission interval [sec.], default 60 min
  TXMODE             = RM2M_TXMODE_TRIG,    // Connection type, default "Interval"
}

/* Global constants and system configurations */
const
{
  INPUT_CH_POLL_ITV   = 250,                // Polling interval for the counter inputs

  DEFAULT_COLOR      = 0x00E20074,          // LED colour
  CNT_RESET_TIME     = 3000,                // Time (ms) for which the button must be pressed to reset
                                            // the counter 
}


/* Size and index specifications for the configuration blocks and measurement data block */
const
{
  CFG_BASIC_INDEX    = 7,                   // Config block 7 contains the basic config
  CFG_BASIC_SIZE     = 5,                   // Transmission interval (u32) + Connection type (u8)

  HISTDATA_SIZE      = 3 * 4 + 1,           // 3 channels (2x u32 + 1x s32) + "Split-tag" (u8)
}


/* Global variables to store the current configuration */
static iTxItv;                              // current transmission interval [sec.]
static iTxMode;                             // current connection type (0 = interval,
                                            // 1 = wakeup, 2 = online)

/* Global variables for the remaining time until certain actions are triggered */
static iTxTimer;                            // sec. until the next transmission
static iRecordRequiered ;                   // Recording is required
static iGamePaused;                         // Game paused Flag. Monitoring stopped if set. The ball can
                                            // be taken out of the goal (0 = game is running, 1 = game paused)


/* Global variables for the current counter readings and the resetting of the counters */
static iPlayer1Cnt;                         // current counter reading of the Player1 counter
static iPlayer2Cnt;                         // current the counter reading of the Player2 counter
static iDiffCnt;                            // difference Player2 counter - Player1 counter
static iLongPushDetected;                   // long key press detected

/* application entry point */
main()
{
  /* Temporary memory for the index of a public function and the return value of a function             */  
  new iIdx, iResult;

  /* Initialisation of the button -> Evaluation by the script activated  
     - Determining the function index that should be called up when pressing or releasing the button
     - Transferring the index to the system and inform it that the button is controlled by the script
     - Index and return value of the init function are issued by the console                            */
  iIdx = funcidx("KeyChanged");                        
  iResult = Switch_Init(SWITCH_MODE_SCRIPT, iIdx);     
  printf("Switch_Init(%d) = %d\r\n", iIdx, iResult); 

  /* Initialisation of the LED -> Control via script activated */  
  Led_Init(LED_MODE_SCRIPT);

  /* Initialisation of a 1 sec. timer used for the general program sequence
     - Determining the function index that should be executed 1x per sec.
     - Transferring the index to the system
     - Index and function return value used to generate the timer are issued via the console            */	
  iIdx = funcidx("Timer1s");
  iResult = rM2M_TimerAdd(iIdx);
  printf("rM2M_TimerAdd(%d) = %d\r\n", iIdx, iResult);

    /* Initialisation of an ms timer for polling the counter inputs and recording the data
     - Determining the index of the function that should  be executed after the timer expires
     - Transferring the index to the system
     - Index and function return value used to generate the timer are issued via the console            */
  iIdx = funcidx("Timer_ms");
  iResult = rM2M_TimerAddExt(iIdx,true,INPUT_CH_POLL_ITV);
  printf("rM2M_TimerAddExt(%d) = %d\r\n", iIdx, iResult);

  /* Specification of the function that should be called up when a config block is changed
     - Determining the function index called up when changing one of the config blocks
     - Transferring the index to the system
     - Index and init function return values are issued via the console                                 */	
  iIdx = funcidx("ReadConfig");
  iResult = rM2M_CfgOnChg(iIdx);
  printf("rM2M_CfgOnChg(%d) = %d\r\n", iIdx, iResult);

  /* Read out the basic configuration. If config block 7 is still empty (first program start), the
     basic configuration is initialised with the standard values.                                       */
  ReadConfig(CFG_BASIC_INDEX);

  /* Initialize both universal inputs in counter mode. The signal must be 10ms constant for a pulse to
     be detected (debouncing).                                                                          */
  UI_Init(UI_CHANNEL1, UI_CHT_SI_DCTR, 10);
  UI_Init(UI_CHANNEL2, UI_CHT_SI_DCTR, 10);

    /* Setting the counter to 0 immediately triggers a transmission.
     You could also refrain from setting it to 0, as all variables in PAWN are initialised with 0
     when they are created. However, it was completed at this point for the purpose of a better
     understanding.                                                                                     */
  iTxTimer  = 0;

  iRecordRequiered = 1;                   // Set "Record required" flag

  /* Setting the connection type */
  rM2M_TxSetMode(iTxMode);
}

/* 1sec. timer is used for the general program sequence */
public Timer1s()
{
  Handle_Led();                             // Control of the LED
  Handle_Transmission();                    // Control of the transmission
}

/* ms Timer, used for polling the digital inputs and recording the data */
public Timer_ms()
{
  Handle_Record();                          // Control of the record
}

/* Function to control the LED */
Handle_Led()
{
  new iTxStatus;                            // Temporary memory for the connection status
  
  iTxStatus = rM2M_TxGetStatus();           // Read current connection status from the system
  
  if(iTxStatus & RM2M_TX_ACTIVE)            // If a GPRS connection is currently established ->
  {
    Led_Off();                              // Switch off LED
    if(iGamePaused)Led_On(0x00FFFF00);      // If game is paused -> Switch on LED (yellow)
    else Led_On(DEFAULT_COLOR);             // Otherwise -> Switch on LED (default LED colour)
  }
  /* If a connection attempt is currently being executed or the delay until the retry is in progress -> */
  else if(iTxStatus & (RM2M_TX_STARTED|RM2M_TX_RETRY)) 
  {
    Led_Off();                              // Switch off LED
    if(iGamePaused)Led_Flicker(0, 0x00FFFF00);// If game is paused -> LED flickers continuously (yellow)
    else Led_Flicker(0, DEFAULT_COLOR);       //Otherwise -> LED flickers continuously (default LED colour)
  }
  else if( iTxStatus & RM2M_TX_FAILED)      // If the last connection attempt failed ->
  {
    Led_Off();                              // Switch off LED
    Led_Blink(0, 0x00FF0000);               // LED flashes red continuously
  }
  else                                      // Otherwise ->
  {
    Led_Off();                              // Switch off LED
    if(iGamePaused)Led_On(0x00FFFF00);      // If game is paused -> Switch on LED (yellow)
  }
}

/* Function to generate the transmission interval */
Handle_Transmission()
{
  iTxTimer--;                               // Counter counting down the sec. to the next transmission

  // If the counter expires in the next sec. -> set "Record required" flag
  if(iTxTimer == 1)iRecordRequiered = 1;
  else if(iTxTimer <= 0)                    // Otherwise -> When the counter has expired ->
  {
    rM2M_TxStart();                         // Establish a connection to the server
    iTxTimer = iTxItv;                      // Reset counter var. to current transmission interval [sec.]
  }
}

/* Function for polling the digital inputs and recording the data */
Handle_Record()
{
  /* Temporary memory in which the data record to be saved is compiled. */  
  new aRecData{HISTDATA_SIZE};  

  new iResult;                              // Temporary memory for the return value of a function
  new iValue;                               // Temporary memory for the raw value read from the UIN

  if(!iGamePaused)                          // If the game is not paused ->
  {

    /* Player 1 counter ---------------------------------------------------------------------------------- */
    iResult = UI_GetValue(UI_CHANNEL1, iValue); // Read the counter reading from UI1
    if(iResult < OK)                        // If the counter reading could not be read ->
    {
      printf("Read UI Channel 1: %d\r\n", iResult);//Issue the function's return value via the console
    }
    else                                    // Otherwise (counter reading could be read) ->
    {
      UI_ResetCounter(UI_CHANNEL1);         // Reset counter reading of UI1

      if (iValue)                           // If the light barrier 1 has been interrupted at least once
      {
        iPlayer1Cnt +=1;                    // Increase Player 1 counter by one
        iRecordRequiered = 1;               // Set "Record required" flag
        iGamePaused = 1;                    // Set "Game paused flag"
      }
    }

    /* Player 2 counter --------------------------------------------------------------------------------- */
    iResult = UI_GetValue(UI_CHANNEL2, iValue); // Read the counter reading from UI2
    if(iResult < OK)                        // If the counter reading could not be read ->
    {
      printf("Read UI Channel 2: %d\r\n", iResult);//Issue the function's return value via the console
    }
    else                                    // Otherwise (counter reading could be read) ->
    {
      UI_ResetCounter(UI_CHANNEL2);         // Reset counter reading of UI2

      if (iValue)                           // If the light barrier 2 has been interrupted at least once
      {
        iPlayer2Cnt +=1;                    // Increase Player 2 counter by one
        iRecordRequiered = 1;               // Set "Record required" flag
        iGamePaused = 1;                    // Set "Game paused flag"
      }
    }
  }
  if(iRecordRequiered)                      // If a recording is required->
  {    

    /* Difference Player 2 counter - Player 1 counter ------------------------------------------------------ */
    iDiffCnt = iPlayer2Cnt - iPlayer1Cnt;

   /* Compile the data record to be saved in the "aRecData" temporary memory
       - The first byte (position 0 in the "aRecData" array) is set to 0 so that the server copies
         the data record into measurement data channel 0 upon receipt, as specified during the design
         of the connector
       - The Player 1 counter is copied to position 1-4. Data type: u32
       - The Player 2 counter is copied to position 5-8. Data type: u32
       - The difference is copied to position 9-12. Data type: s32                                      */
    aRecData{0} = 0;                        // "Split-tag" 
    rM2M_Pack(aRecData,  1,   iPlayer1Cnt,  RM2M_PACK_BE + RM2M_PACK_U32);
    rM2M_Pack(aRecData,  5,   iPlayer2Cnt,  RM2M_PACK_BE + RM2M_PACK_U32);
    rM2M_Pack(aRecData,  9,   iDiffCnt,     RM2M_PACK_BE + RM2M_PACK_S32);

    /* Transfer compounded data record to the system to be recorded */
    rM2M_RecData(0, aRecData, HISTDATA_SIZE);

    /* Issue current measurement values via the console */
    printf("Payer 1:%d Player 2:%d DIFF:%d\r\n",iPlayer1Cnt, iPlayer2Cnt, iDiffCnt);

    iRecordRequiered = 0;                   // Clear "Record required" flag

    if(iTxMode!= RM2M_TXMODE_ONLINE)        // If the connection type is not set to online ->
    {
      /* Set count variable for seconds until the next transmission to 0. This ensures that a transmission
         is triggered the next time the "Handle_Transmission" function is called up by the "Timer1s"
         function.                                                                                      */
      iTxTimer = 0;
    }
  }
}

public KeyChanged(iKeyState)
{
  /* Temporary memory for the index of a public function and the return value of a function             */
  new iIdx, iResult;     

  printf("K:%d\r\n", iKeyState);            // Issue action via the console (0=release, 1=press)

  if(iKeyState)                             // If the button has been pressed ->
  {
    /* Starts a timer by means of which a long key press is to be detected. If the timer expires, a
       flag is set by the function transferred.
     - Determining the function index that should be called up when the timer expires
     - Transferring the index to the system                                                             */
    iIdx = funcidx("LongPushDetect");
    rM2M_TimerAddExt(iIdx, false, CNT_RESET_TIME);
  }
  else                                      // Otherwise -> If the button has been released ->
  {
    if(iLongPushDetected)                   // If the button has been pressed for a long time ->
    {
      iLongPushDetected = 0;                // Delete "long key press detected" flag

      // Reset all counters
      iPlayer1Cnt = 0;
      iPlayer2Cnt = 0;
      iDiffCnt    = 0;

      iRecordRequiered = 1;                 // Set "Record required" flag
      iGamePaused = 0;                      // Reset "Game paused flag" (Monitoring of the light barriers
                                            // active again)

    }
    else                                    // Otherwise (i.e. the button was pressed only briefly) ->
    {

      /* Delete the timer for long keystroke detection if the button has been pressed only for a short
         time so that it cannot expire and therefore the "long key press detected" flag is not set.
         - Determining the function index that should be called up when the timer expires
         - Transferring the index to the system so that the timer can be deleted
         - If it was not possible to delete the timer -> Index and TimerRemove function return values
           are issued via the console                                                                   */
      iIdx = funcidx("LongPushDetect");
      iResult = rM2M_TimerRemoveExt(iIdx);
      if(iResult != OK) printf("rM2M_TimerRemove(%d) = %d\r\n", iIdx, iResult);

      if(iGamePaused)                       // If the game is paused ->
      {
        iGamePaused = 0;                    // Reset "Game paused flag" (Monitoring of the light barriers
                                            // active again)
        UI_ResetCounter(UI_CHANNEL1);       // Reset counter reading of UI1
        UI_ResetCounter(UI_CHANNEL2);       // Reset counter reading of UI2
      }
      else
      {
        if(iTxMode!= RM2M_TXMODE_ONLINE)    // If the connection type is not set to online ->
        {
          /* Set count variable for seconds until the next transmission to 0. This ensures that a transmission
            is triggered the next time the "Handle_Transmission" function is called up by the "Timer1s"
            function.                                                                                      */
          iTxTimer = 0;
        }
      }

    }


  }

}

/* Function that is called when the timer to detect a long key press has expired  */
public LongPushDetect()
{
  print("Long Push Detected\r\n");          // Issue the detection of a long key press via the console
  iLongPushDetected = 1;                    // Set "long key press detected" flag
}

/* Function that makes it possible to react to a changed configuration received from the server */
public ReadConfig(cfg)
{
  //If the changed configuration is the basic config -> */
  if(cfg == CFG_BASIC_INDEX)
  {
    new aData{CFG_BASIC_SIZE};              // Temporary memory for the basic config read from the system
    new iSize;                              // Temporary memory for the size of the basic config in bytes
    new iTmp;                               // Temporary memory for a basic config parameter

    /* Read basic config from the system and copy to the temporary memory. The
       number of the config block and return value of the read function (number of bytes or error code)
       is then issued via the console                                                                   */
    iSize = rM2M_CfgRead(cfg, 0, aData, CFG_BASIC_SIZE);
    printf("Cfg %d size = %d\r\n", cfg, iSize);  

    /* If the number of read bytes is lower than the size of the basic config ->
       Info: Error codes are negative                                                                   */
    if(iSize < CFG_BASIC_SIZE)              
    {
      /* The following block initially copies the default values to the temporary memory for the read
         basic config and then sets the temporary memory for the size of the basic config to the current
         size. This ensures that the following "IF" is executed during re-initialisation and when
         changes are received. If special actions have to be executed for individual parameters,
         it is thus not necessary to implement these separately for both cases.                         */
      iTmp = ITV_TRANSMISSION;
      rM2M_Pack(aData, 0, iTmp,   RM2M_PACK_BE + RM2M_PACK_U32);
      iTmp = TXMODE;
      rM2M_Pack(aData, 4, iTmp,  RM2M_PACK_BE + RM2M_PACK_U8);
      iSize = CFG_BASIC_SIZE;
      print("created new Config #7\r\n");
    }

    /* If the number of read bytes at least equates to the size of the basic config -> */
    if(iSize >= CFG_BASIC_SIZE)
    {
      /* Copy transmission interval (u32, Big Endian) at position 0-3 from the temporary memory for the
         read basic config into the temporary memory for a parameter                                    */
      rM2M_Pack(aData, 0, iTmp,  RM2M_PACK_BE + RM2M_PACK_U32 + RM2M_PACK_GET);
      if(iTmp != iTxItv)     // If the received value does not correspond to that of the global variables ->
      {
        printf("iTxItv changed to %d s\r\n", iTmp);   // Issue received value via the console
        iTxItv = iTmp;                                // Copy received value into the global variable
      }

      /* Copy connection type (u8) at position 4 from the temporary memory for the read basic config into
         the temporary memory for a parameter                                                           */
      rM2M_Pack(aData, 4, iTmp,  RM2M_PACK_BE + RM2M_PACK_U8 + RM2M_PACK_GET);
      if(iTmp != iTxMode)    // If the received value does not correspond to that of the global variables ->
      {
        rM2M_TxSetMode(iTmp);                         // Set connection type to the received value
        printf("iTxMode changed to %d\r\n", iTmp);    // Issue received value via the console
        iTxMode = iTmp;                               // Copy received value into the global variable
      }
    }
  }
}
