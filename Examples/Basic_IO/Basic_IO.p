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
forward public Timer_ms();                  // ms Timer for polling the digital inputs
forward public ReadConfig(cfg);             // called up when one of the config blocks is changed
forward public KeyChanged(iKeyState);       // called up when the button is pressed or released

/* Standard values to initialise the configuration */
const
{
  CNT_INPUT_CHANNELS  = 6,                  // Number of digital inputs

  CNT_OUTPUT_CHANNELS = 2,                  // Number of digital outputs

  INPUT_CH_POLL_ITV   = 250,                // Polling interval for the digital inputs
  INPUT_CH_GPIO_CNT   = 4,                  // Number of GPIOs used for digital inputs
  INPUT_CH_UI1        = 4,                  // No of the digital input realized by using UI1
  INPUT_CH_UI2        = 5,                  // No of the digital input realized by using UI2

  CHANNEL_OFF         = 0,                  // Digital in/output is switched off
  OUTPUT_OFF          = 0,                  // Digital output to "low" (not switched)

  OUTPUT_FIRST_CH     = 4,                  // First GPIO used for digital outputs

  ITV_TRANSMISSION  = 1 * 60 * 60,          // Transmission interval [sec.], default 60 min
  TXMODE            = RM2M_TXMODE_TRIG,     // Connection type, default "Interval"

  DEFAULT_COLOR     = 0x00008ECF,           // LED colour
}

/* Size and index specifications for the configuration blocks and measurement data block */
const
{
  CFG_CHANNELS_INDEX = 1,                   // Config block 1 contains the measurement channel config
  CFG_CHANNELS_SIZE  = 102,                 // 6x ( channel name (string, 16 characters), mode (u8) )

  CFG_OUTPUT_INDEX   = 3,                   // Config block 3 contains the output channel config
  CFG_OUTPUT_SIZE    = 36,                  // 2x ( channel name (string, 16 characters), mode (u8),
                                            //      setpoint (u8) )

  CFG_BASIC_INDEX    = 7,                   // Config block 7 contains the basic config
  CFG_BASIC_SIZE     = 5,                   // Transmission interval (u32) + Connection type (u8)


  HISTDATA_SIZE      = 16,
}

/* Global variables to store the current configuration */
static iTxItv;                              // current transmission interval [sec.]
static iTxMode;                             // current connection type (0 = interval,
                                            // 1 = wakeup, 2 = online)
static aDiMode[CNT_INPUT_CHANNELS];         // Modes of the digital inputs (0 = off, 1 = on)
static aDoMode[CNT_OUTPUT_CHANNELS];        // Modes of the digital outputs (0 = off, 1 = on)
static aDoSetpoint[CNT_OUTPUT_CHANNELS];    // Setpoint of the digital outputs (0 = "low", 1 ="high")


/* Global variables for the remaining time until certain actions are triggered */
static iTxTimer;                            // sec. until the next transmission
static iRecordRequiered ;                   // Recording is required


/* Global variables for the current levels at the digital inputs */
static aDiValue[CNT_INPUT_CHANNELS];

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

  /* Initialisation of an ms timer for polling the digital inputs and recording the data
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


  /* Read out the measurement channel config. If config block 1 is still empty (first program start), the
     measurement channel configis initialised with the standard values.                                 */
  ReadConfig(CFG_CHANNELS_INDEX);

  /* Read out the output channel config. If config block 3 is still empty (first program start), the
     output channel config is initialised with the standard values.                                     */
  ReadConfig(CFG_OUTPUT_INDEX);

  /* Read out the basic configuration. If config block 7 is still empty (first program start), the
     basic configuration is initialised with the standard values.                                       */
  ReadConfig(CFG_BASIC_INDEX);

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
    Led_On(DEFAULT_COLOR);                  // Switch on LED (default LED colour)
  }
  /* If a connection attempt is currently being executed or the delay until the retry is in progress -> */
  else if(iTxStatus & (RM2M_TX_STARTED|RM2M_TX_RETRY)) 
  {
    Led_Off();                              // Switch off LED
    Led_Flicker(0, DEFAULT_COLOR);          // LED flickers continuously (default LED colour)
  }
  else if( iTxStatus & RM2M_TX_FAILED)      // If the last connection attempt failed ->
  {
    Led_Off();                              // Switch off LED
    Led_Blink(0, 0x00FF0000);               // LED flashes red continuously
  }
  else                                      // Otherwise ->
    Led_Off();                              // Switch off LED
}

/* Function to generate the transmission interval */
Handle_Transmission()
{
  iTxTimer--;                               // Counter counting down the sec. to the next transmission

  // If the counter expires in the next sec. -> set “Record required” flag
  if(iTxTimer == 1)iRecordRequiered = 1;
  else if(iTxTimer <= 0)                    // Otherwise -> When the counter has expired ->
  {
    rM2M_TxStart();                         // Establish a connection to the server
    iTxTimer = iTxItv;                      // Reset counter var. to current transmission interval [sec.]
  }
}

/* Function that enables a transmission to be triggered when the button is pressed */
public KeyChanged(iKeyState)
{
  printf("K:%d\r\n", iKeyState);            // Issue action via the console (0=release, 1=press)

  if(!iKeyState)                            // If the button has been released->
  {
    /* Set count variable for seconds until the next transmission to 0. This ensures that a transmission
       is triggered the next time the "Handle_Transmission" function is called up by the "Timer1s"
       function.                                                                                        */
    iTxTimer = 0;

    iRecordRequiered = 1;                   // Set "Record required" flag
  }                                              
}

/* Function for polling the digital inputs and recording the data */
Handle_Record()
{
  /* Temporary memory in which the data record to be saved is compiled. */
  new aRecData{HISTDATA_SIZE};

  new iTmp;                                 // Temporary memory for the current level at an input

  for(new i=0; i < CNT_INPUT_CHANNELS;i++)  // For all digital inputs ->
  {
    if(aDiMode[i] != CHANNEL_OFF)           // If the digital input is not turned off->
    {
      //If the input is realized via an GPIO-> read level with RM2M_GpioGet into the Temporary memory
      if( (i<INPUT_CH_GPIO_CNT))iTmp=rM2M_GpioGet(i);
      //If the input is realized via UI1-> read level with UI_GetValue into the Temporary memory
      else if(i == INPUT_CH_UI1)UI_GetValue(UI_CHANNEL1, iTmp);
      //If the input is realized via UI2-> read level with UI_GetValue into the Temporary memory
      else if(i == INPUT_CH_UI2)UI_GetValue(UI_CHANNEL2, iTmp);
    }
    else iTmp = 0xFF;                       // Otherwise -> Set Temporary memory to "NaN"

    // If the currently read level does not match that one of the global variable ->
    if(iTmp!=aDiValue[i])
    {
      aDiValue[i] = iTmp;                   // Copy current level to the global variable
      iRecordRequiered = 1;                 // Set "Record required" flag
    }
  }

  if(iRecordRequiered)                      // If a recording is required->
  {
    new aDoValue[CNT_OUTPUT_CHANNELS];      // Temporary memory for the setpoints of the digital outputs
    new aSysValues[TIoTbox_SysValue];       // Temporary memory for the int. measurement values (VBat,
                                            // VUsb, temp)
    new iGSM_Level;                         // Temporary memory for the GSM level

    // For all digital outputs
    for(new i=0; i < CNT_OUTPUT_CHANNELS;i++)
    {
      //If the output is not turned off-> Copy setpoint from the global variable to the temporary memory
      if(aDoMode[i] != CHANNEL_OFF)aDoValue[i]=aDoSetpoint[i];
      else aDoValue[i] = 0xFF;              // Otherwise -> Set Temporary memory to "NaN"
    }

    IoTbox_GetSysValues(aSysValues);        // Read out the current int. measurement values (VBat, VUsb,
                                            // temp)
    iGSM_Level=rM2M_GSMGetRSSI();           // Read out the current GSM level


    /* Compile the data record to be saved in the "aRecData" temporary memory
       - The first byte (position 0 in the "aRecData" array) is set to 0 so that the server copies
         the data record into measurement data channel 0 upon receipt, as specified during the design
         of the connector
       - The level at digital input 1 is copied to           position 1. Data type: u8
       - The level at digital input 2 is copied to           position 2. Data type: u8
       - The level at digital input 3 is copied to           position 3. Data type: u8
       - The level at digital input 4 is copied to           position 4. Data type: u8
       - The level at digital input 5 is copied to           position 5. Data type: u8
       - The level at digital input 6 is copied to           position 6. Data type: u8
       - The setpoint of digital output 1 is copied to       position 7. Data type: u8
       - The setpoint of digital output 2 is copied to       position 8. Data type: u8
       - The battery voltage (VBat) is copied to             position 9-10. Data type: s16
       - The USB charging voltage (VUsb) is copied to        position 11-12. Data type: s16
       - The temperature (Temp) is copied to                 position 13-14. Data type: s16
       - The GSM level is copied to                          position 15. Data type: s8                 */
    aRecData{0} = 0;                        // "Split-tag" 
    rM2M_Pack(aRecData,  1,   aDiValue[0],      RM2M_PACK_BE + RM2M_PACK_U8);
    rM2M_Pack(aRecData,  2,   aDiValue[1],      RM2M_PACK_BE + RM2M_PACK_U8);
    rM2M_Pack(aRecData,  3,   aDiValue[2],      RM2M_PACK_BE + RM2M_PACK_U8);
    rM2M_Pack(aRecData,  4,   aDiValue[3],      RM2M_PACK_BE + RM2M_PACK_U8);
    rM2M_Pack(aRecData,  5,   aDiValue[4],      RM2M_PACK_BE + RM2M_PACK_U8);
    rM2M_Pack(aRecData,  6,   aDiValue[5],      RM2M_PACK_BE + RM2M_PACK_U8);
    rM2M_Pack(aRecData,  7,   aDoValue[0],      RM2M_PACK_BE + RM2M_PACK_U8);
    rM2M_Pack(aRecData,  8,   aDoValue[1],      RM2M_PACK_BE + RM2M_PACK_U8);
    rM2M_Pack(aRecData,  9,   aSysValues.VBat,  RM2M_PACK_BE + RM2M_PACK_S16);
    rM2M_Pack(aRecData,  11,  aSysValues.VUsb,  RM2M_PACK_BE + RM2M_PACK_S16);
    rM2M_Pack(aRecData,  13,  aSysValues.Temp,  RM2M_PACK_BE + RM2M_PACK_S16);
    rM2M_Pack(aRecData,  15,  iGSM_Level,       RM2M_PACK_BE + RM2M_PACK_S8);


   /* Transfer compounded data record to the system to be recorded */
    rM2M_RecData(0, aRecData, HISTDATA_SIZE);


    /* Issue current measurement values via the console */
    printf("IN1:%d IN2:%d IN3:%d IN4:%d IN5:%d IN6:%d OUT1:%d OUT2:%d Vb:%d Vu:%d Ti:%d GSM:%d\r\n",
            aDiValue[0],aDiValue[1],aDiValue[2],aDiValue[3],aDiValue[4],aDiValue[5],
            aDoValue[0],aDoValue[1],aSysValues.VBat, aSysValues.VUsb, aSysValues.Temp,iGSM_Level);

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


/* Function that makes it possible to react to a changed configuration received from the server */
public ReadConfig(cfg)
{
  //If the changed configuration is the measurement channel config ->
  if (cfg == CFG_CHANNELS_INDEX)
  {
    new aData{CFG_CHANNELS_SIZE};           // Temporary memory for the measurement channel config read from the system
    new iSize;                              // Temporary memory for the size of the measurement channel config in bytes
    new iTmp;                               // Temporary memory for a measurement channel config parameter

    /* Read measurement channel config from the system and copy to the temporary memory. The
       number of the config block and return value of the read function (number of bytes or error code)
       is then issued via the console                                                                   */
    iSize = rM2M_CfgRead(cfg, 0, aData, CFG_CHANNELS_SIZE);
    printf("Cfg %d size = %d\r\n", cfg, iSize);

    /* If the number of read bytes is lower than the size of the measurement channel config ->
       Info: Error codes are negative                                                                   */
    if(iSize < CFG_CHANNELS_SIZE)
    {
      /* The following block initially copies the default values to the temporary memory for the read
         measurement channel config and then sets the temporary memory for the size of the measurement
         channel config to the current size. This ensures that the following "IF" is executed during
         re-initialisation and when changes are received. If special actions have to be executed for
         individual parameters, it is thus not necessary to implement these separately for both cases.  */
      for(new i=0; i < CNT_INPUT_CHANNELS;i++) //For all digital inputs ->
      {
        iTmp = CHANNEL_OFF;
        rM2M_Pack(aData, 16+(i*17), iTmp,   RM2M_PACK_BE + RM2M_PACK_U8);
      }
      iSize = CFG_CHANNELS_SIZE;
      print("created new Config #1\r\n");
    }

    /* If the number of read bytes at least equates to the size of the measurement channel config -> */
    if(iSize >= CFG_CHANNELS_SIZE)
    {
      for(new i=0; i < CNT_INPUT_CHANNELS;i++) //For all digital inputs ->
      {
        /* Copy mode (U8, big endian) for the digital input at position 16 from the temporary memory for
           the read measurement channel config to the temporary memory for a parameter                  */
        rM2M_Pack(aData, 16+(i*17), iTmp,  RM2M_PACK_BE + RM2M_PACK_U8 + RM2M_PACK_GET);
        if(iTmp != aDiMode[i]) // If the received value does not correspond to that of the global variables ->
        {
          printf("Input Ch%d Mode changed to %d\r\n",i+1, iTmp); // Issue received value via the console
          aDiMode[i] = iTmp;                                     // Copy received value into the global variable

          // If the input is realized by using an GPIO and is not switched off-> Set GPIO to input
          if( (i<INPUT_CH_GPIO_CNT)&& (aDiMode[i] != CHANNEL_OFF))rM2M_GpioDir(i, RM2M_GPIO_INPUT);
          else if(i== INPUT_CH_UI1)         // Otherwise-> If the input is realized by using UI1->
          {
            //If the input is switched off-> Deactivate universal input 1
            if(aDiMode[INPUT_CH_UI1] == CHANNEL_OFF)UI_Close(UI_CHANNEL1);
            else UI_Init(UI_CHANNEL1, UI_CHT_SI_DIGITAL, 10);    //Otherwise-> Activate universal input 1
          }
          else if(i== INPUT_CH_UI2)         //Otherwise-> If the input is realized by using UI2->
          {
            //If the input is switched off-> Deactivate universal input 2
            if(aDiMode[INPUT_CH_UI2] == CHANNEL_OFF)UI_Close(UI_CHANNEL2);
            else UI_Init(UI_CHANNEL2, UI_CHT_SI_DIGITAL, 10);    //Otherwise-> Activate universal input 2
          }
        }
      }
    }
  }
  //Otherwise -> If the changed configuration is the output channel config ->
  if (cfg == CFG_OUTPUT_INDEX)
  {
    new aData{CFG_OUTPUT_SIZE};             // Temporary memory for the output channel config read from the system
    new iSize;                              // Temporary memory for the size of the output channel config in bytes
    new iTmp;                               // Temporary memory for a output channel config parameter

    /* Read output channel config from the system and copy to the temporary memory. The
       number of the config block and return value of the read function (number of bytes or error code)
       is then issued via the console                                                                   */
    iSize = rM2M_CfgRead(cfg, 0, aData, CFG_OUTPUT_SIZE);
    printf("Cfg %d size = %d\r\n", cfg, iSize);

    /* If the number of read bytes is lower than the size of the output channel config ->
      Info: Error codes are negative                                                                    */
    if(iSize < CFG_OUTPUT_SIZE)
    {

      /* The following block initially copies the default values to the temporary memory for the read
         output channel config and then sets the temporary memory for the size of the output channel
         config to the current size. This ensures that the following "IF" is executed during
         re-initialisation and when changes are received. If special actions have to be executed for
         individual parameters, it is thus not necessary to implement these separately for both cases.  */
      for(new i=0; i < CNT_OUTPUT_CHANNELS;i++) //Für alle Digitalausgänge ->
      {
        iTmp = CHANNEL_OFF;
        rM2M_Pack(aData, 16+(i*18), iTmp,   RM2M_PACK_BE + RM2M_PACK_U8);
        iTmp = OUTPUT_OFF;
        rM2M_Pack(aData, 17+(i*18), iTmp,   RM2M_PACK_BE + RM2M_PACK_U8);
      }


      iSize = CFG_OUTPUT_SIZE;
      print("created new Config #3\r\n");
    }

    /* If the number of read bytes at least equates to the size of the output channel config -> */
    if(iSize >= CFG_OUTPUT_SIZE)
    {
      for(new i=0; i < CNT_OUTPUT_CHANNELS;i++) //For all digital outputs ->
      {
        /* Copy mode (U8, big endian) for the digital output at position 16 from the temporary memory for
           the read output channel config to the temporary memory for a parameter                       */
        rM2M_Pack(aData, 16+(i*18), iTmp,  RM2M_PACK_BE + RM2M_PACK_U8 + RM2M_PACK_GET);
        if(iTmp != aDoMode[i])  // If the received value does not correspond to that of the global variables ->
        {
          printf("Output Ch%d Mode changed to %d\r\n",i+1, iTmp);// Issue received value via the console
          aDoMode[i] = iTmp;                                     // Copy received value into the global variable

          if(aDoMode[i] != CHANNEL_OFF)     //If the output is not turned off ->
          {
            rM2M_GpioDir(OUTPUT_FIRST_CH+i, RM2M_GPIO_OUTPUT);   //Set GPIO to OUTPUT

            //If the setpoint is not set to "low" -> Set GPIO to "high"
            if(aDoSetpoint[i] != OUTPUT_OFF)rM2M_GpioSet(OUTPUT_FIRST_CH+i, RM2M_GPIO_HIGH);
            else rM2M_GpioSet(OUTPUT_FIRST_CH+i, RM2M_GPIO_LOW); //Otherwise -> Set GPIO to "low"
          }
          else rM2M_GpioDir(OUTPUT_FIRST_CH+i, RM2M_GPIO_INPUT); //Otherwise -> Set GPIO to INPUT

          iRecordRequiered = 1;             // Set "Record required" flag
        }

        /* Copy setpoint (u8, big endian) for the digital output at position 17 from the temporary memory
           for the read output channel config to the temporary memory for a parameter                   */
        rM2M_Pack(aData, 17+(i*18), iTmp,  RM2M_PACK_BE + RM2M_PACK_U8 + RM2M_PACK_GET);
        if(iTmp != aDoSetpoint[i]) // If the received value does not correspond to that of the global variables ->
        {
          printf("Output Ch%d Setpoint changed to %d\r\n",i+1, iTmp);// Issue received value via the console
          aDoSetpoint[i] = iTmp;                                 // Copy received value into the global variable

          if(aDoMode[i] != CHANNEL_OFF)     //If the output is not turned off ->
          {
            //If the setpoint is not set to "low" -> Set GPIO to "high"
            if(aDoSetpoint[i] != OUTPUT_OFF)rM2M_GpioSet(OUTPUT_FIRST_CH+i, RM2M_GPIO_HIGH);
            else rM2M_GpioSet(OUTPUT_FIRST_CH+i, RM2M_GPIO_LOW); //Otherwise -> Set GPIO to "low"

            iRecordRequiered = 1;           // Set "Record required" flag
          }
        }
      }
    }
  }
  //Otherwise -> If the changed configuration is the basic config -> */
  else if(cfg == CFG_BASIC_INDEX)
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
