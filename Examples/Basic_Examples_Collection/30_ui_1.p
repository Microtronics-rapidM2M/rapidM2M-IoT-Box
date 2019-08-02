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
 * 
 * Extended "UI" Test application
 *
 * Reads the last valid values of all two UI channels periodically (record interval) and
 * stores the generated data record in the flash of the system. The measurement data generated
 * this way is then transmitted periodically (transmission interval) to the server. 
 * 
 * Note: To use the recorded data within the interface of the server (e.g. reports, visualisations, graphics, etc.)
 *       it is necessary to define a Data Descriptor (see 30_ui_1.txt)
 * 
 * Only compatible with rapidM2M M3
 * 
 * @version 20190711
 */

/* Path for hardware-specific include file */
#include <rapidM2M IoT-Box\iotbox>

/* Forward declarations of public functions */
forward public Timer1s();

const
{
  INTERVAL_RECORD = 60,                     // Interval of record [s]
  INTERVAL_TX     = 10 * 60,                // Interval of transmission [s]
  
  HISTDATA0_SIZE = UI_NUM_CHANNELS * 4 + 1, // Measurement data block consists of: "Split-tag" (u8) + UI1 (u32) + UI2 (u32)
}

/* Global variables for the remaining time until certain actions are triggered */
static iRecTimer;                           // Sec. until the next recording
static iTxTimer;                            // Sec. until the next transmission 

/* Application entry point */
main()
{
  /* Temporary memory for the index of a public function and the return value of a function  */
  new iIdx, iResult;

  /* Initialisation of a 1 sec. timer used for the general program sequence
     - Determining the function index that should be executed 1x per sec.
     - Transferring the index to the system
     - Index and function return value used to generate the timer are issued via the console */
  iIdx = funcidx("Timer1s");
  iResult = rM2M_TimerAdd(iIdx);
  printf("rM2M_TimerAdd(%d) = %d\r\n", iIdx, iResult);
  
  // Sets sample rate to 128 Hz (default: 16Hz)
  UI_SetSampleRate(UI_SAMPLE_RATE_128);
  
  /* Initialisation of the two UI channels:
     Channel | Mode            | Filtertime
     ------------------------------------
     UI 1    | Digital counter |   10 ms
     UI 2    | 0 ... 2,5V      |   10 ms
     
     When a channel is used as digital counter, the filtertime determines how long a signal
     level must be constant to trigger a level change. When a channel is used as 0...2,5V
     interface, the filtertime determines the time in which the analog signal is averaged. */
  UI_Init(UI_CHANNEL1, UI_CHT_SI_DCTR, 10);
  UI_Init(UI_CHANNEL2, UI_CHT_SI_A002V, 10);
  
  iRecTimer = INTERVAL_RECORD;              // Sets counter variable to defined record interval
  iTxTimer  = INTERVAL_TX;                  // Sets counter variable to defined transmission interval
  
  rM2M_TxStart();                           // Initiates a connection to the server
}

/* 1 sec. timer is used for the general program sequence */
public Timer1s()
{
  iRecTimer--;                              // Counter counting down the sec. to the next recording
  if(iRecTimer <= 0)                        // When the counter has expired ->  
  {
    print("Create Record\r\n");     
    RecordData();                           // Calls up the function to record the data 
    iRecTimer = INTERVAL_RECORD;            // Resets counter variable to defined record interval  
  }
  
  iTxTimer--;                               // Counter counting down the sec. to the next transmission
  if(iTxTimer <= 0)                         // When the counter has expired -> 
  {
    print("Start Transmission\r\n");
    rM2M_TxStart();                         // Initiates a connection to the server 
    iTxTimer = INTERVAL_TX;                 // Resets counter var. to defined transmission interval [sec.]  
  }
  
  // Issues the seconds until the next recording and the next transmission to the console
  printf("iRecTimer=%d iTxTimer=%d\r\n", iRecTimer, iTxTimer);
}

/* Reads the last valid values of all two UI channels, compiles the data record to
   be saved and transfers the compounded data record to the system to be recorded */
RecordData()
{
  new iValue, iResult;                      // Temporary memory for the channel value and the return value of a function
  new aRecData{HISTDATA0_SIZE}              // Temporary memory in which the data record to be saved is compiled
  
  /* Compiles the data record to be saved in the "aRecData" temporary memory. The first
     byte (position 0 in the "aRecData" array) is set to 0 so that the server copies the data
     record into measurement data channel 0 upon receipt, as specified during the design of the
     data descriptor: */
  aRecData{0} = 0;                          // "Split-tag"
  
  /* The for loop gets the measurement values of all two M3 channels and prints them to the console.
     Each measurement is written to the "aRecData" array with calculated byte offset. An index variable
     counts up until it reaches the maximum UI channel number UI_NUM_CHANNELS */
  for(new iIdx=0; iIdx < UI_NUM_CHANNELS; iIdx++)
  {
    /* Gets the measurement value for the specific channel
     - Reading value from channel
     - In case of a problem the index and return value of the UI_GetValue() function are issued by the console  */
    iResult = UI_GetValue(iIdx, iValue);
    if(iResult != OK)
      printf("UI_GetValue(%d) = %d\r\n", iIdx, iResult);
    
    /* Compiles the data record to be saved in the "aRecData" temporary memory.
       Position 0 contains the "Split-tag" -> Offset: 1
       A measurement value consists of 4 bytes -> Offset: iIdx*4 (4 x index variable) */
    rM2M_Pack(aRecData, 1 + iIdx * 4, iValue, RM2M_PACK_U32 + RM2M_PACK_BE);
    
    // Prints the measured channel value to the console
    printf("Channel%d = %d\r\n", iIdx, iValue);
  }
  
  /* Transfers the data record to the system */
  rM2M_RecData(0, aRecData, HISTDATA0_SIZE);
}
