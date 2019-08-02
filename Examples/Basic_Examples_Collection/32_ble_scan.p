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
 * Simple "BLE" example
 *
 * Scans continuously for BLE devices in advertising mode and issues the info and data of the scan response via the console.  
 * The continuous scan for BLE devices is activated by pressing the button. By pressing the button again the scan is deactivated. 
 *
 * Note: Before the initialisation of the BLE scan, the BLE module must be activated.
 *
 * Only compatible with rapidM2M M3
 * Special hardware necessary (BLE module, e.g. Sensirion SHT31 Smart Gadget) 
 *
 * @version 20190704
 */

/* Path for hardware-specific include file */
#include ".\rapidM2M IoT-Box\iotbox"

/* Forward declarations of the public functions */
forward public Timer1s();                   // Called up 1x per sec. for the program sequence
forward public KeyPressed(iKeyState);       // Called up when the button is pressed or released
forward public BLE_Event(event, connhandle, const data{}, len);// Called up when an BLE event (e.g.
                                                               // data has been read) occurs

static bool: bBLE_Init = false;             // Current BLE mode (0 = switched off, 1 = active)

/* Application entry point */
main()
{
  new aId[TrM2M_Id];                                           // Temporary memory for the HW module information
  
  /* Temporary memory for the index of a public function and the return value of a function             */  
  new iIdx, iResult;

  rM2M_GetId(aId);                                             // Retrieves information to identify the rapidM2M hardware

  // Prints "Module identification", "Module type", "Hardware major version" and "Hardware minor version" to the console
  printf("Id: %s\r\n", aId.string);
  printf("Module: %s\r\n", aId.module);
  printf("HW: %d.%d\r\n", aId.hwmajor, aId.hwminor);

  /* Initialisation of a 1 sec. timer used for the general program sequence
     - Determining the function index that should be executed 1x per sec.
     - Transferring the index to the system
     - Index and function return value used to generate the timer are issued via the console            */
  iIdx = funcidx("Timer1s");
  iResult = rM2M_TimerAdd(iIdx);
  printf("rM2M_TimerAdd(%d) = %d\r\n", iIdx, iResult);

  /* Initialisation of the button -> Evaluation by the script activated
     - Determining the function index that should be called up when pressing or releasing the button
     - Transferring the index to the system and informing it that the button is controlled by the script
     - Index and return value of the init function are issued by the console                            */  
  iIdx = funcidx("KeyPressed");
  iResult = Switch_Init(SWITCH_MODE_SCRIPT, iIdx);
  printf("Switch_Init(%d) = %d\r\n", iIdx, iResult);
}

/* 1sec. timer is used for the general program sequence */
public Timer1s()
{
  if(bBLE_Init)                             // If BLE is switched on ->
  {
    new iBleState = BLE_GetState();         // Reads current BLE status from the system

    if(iBleState == BLE_STATE_READY)        // If the BLE interface is ready ->
    {
      BLE_Scan(5, 1);                       // If an "active scan" with 5sec. scan time could be started ->
      printf("---------------------------------------\r\n")
    }
  }
}

/**
 * Function that should be called up when the button is pressed or released
 *
 * @param iKeyState:s32 - Signal level
 *						  0: Button released
 *                        1: Button pressed
 */
public KeyPressed(iKeyState)
{
  new iResult;                              // Temporary memory for the return value of a function

  printf("switch %d\r\n", iKeyState);

  if(iKeyState)
  {
    if(!bBLE_Init)                          // If BLE is switched off ->
    {
      /* Init and configure BLE interface
        - Determining the function index that should be called up when a BLE event occurs
        - Transferring the index to the system
        - Return value of the init function is issued by the console                                 */  
      iResult = BLE_Init(funcidx("BLE_Event"));
      printf("BLE_Init() %d\r\n", iResult);

      bBLE_Init = true;                     // Activates BLE
    }
    else
    {
      BLE_Close();                          // Closes and deactivates BLE interface
      bBLE_Init = false;                    // Switches off BLE
    }
  }
}

/**
 * Function to process the scan response of a device
 *
 * @param sScan:TBLE_Scan - Scan response of a device 
 */
BLE_EvScanned(sScan[TBLE_Scan])
{
  new iIdx;                                 // Temporary memory for the loop counter
  
  // Issues the info of the scan response via the console
  printf("SCAN: %d,", sScan.rssi);
  printf("\"%02X:%02X:%02X:%02X:%02X:%02X\",",
    sScan.addr{0}, sScan.addr{1}, sScan.addr{2},
    sScan.addr{3}, sScan.addr{4}, sScan.addr{5});
  printf("\"%s\",%d {", sScan.name, sScan.addr_type);

  // Issues the manufacturer specific data in hex string format
  for(iIdx=0; iIdx<sScan.msd_len; iIdx++)     
  {
    printf("%02X", sScan.msd{iIdx});        
  }
  printf("}\r\n");
}

/**
 * Function that is called up when a BLE event occurs
 *
 * @param sNotify:TBLE_Notify - Notification data received from a device
 */
BLE_EvNotify(sNotify[TBLE_Notify])
{
  // Issues the notification handle, the length of the notification data (bytes) and the first two bytes of the notification data via the console
  printf("NOTIFY: %d, %d, {%02X%02X}\r\n", sNotify.handle, sNotify.data_len, sNotify.data{0}, sNotify.data{1});
}

/**
 * Function to process the notification data received from a device
 *
 * @param sRead:TBLE_Read - Data read from a device
 */
BLE_EvRead(sRead[TBLE_Read])
{
  // Issues the read handle, the offset of the data, the length of the read data (bytes) and the first two bytes of the read data via the console
  printf("READ: %d, %d, %d, {%02X%02X}\r\n", sRead.handle, sRead.offset, sRead.data_len, sRead.data{0}, sRead.data{1});
}

/**
 * Function that is called up when a BLE event occurs
 *
 * @param event:s32      - BLE event which causes the call up of the callback function 
 * @param connhandle:s32 - Connection handle 
 * @param data[]:u8      - Array that contains the data associated with the event.
 *                         The structure depends on the event which occurs.  
 * @param len:s32        - Size of the data block in bytes 
 */
public BLE_Event(event, connhandle, const data{}, len)
{
  //static const szEvent[]{} =
  //[
  //  "BLE_EVENT_SCAN", "BLE_EVENT_SCAN_RSP", "BLE_EVENT_NOTIFY", "BLE_EVENT_READ"
  //]
  //printf("%s(%d)\r\n", szEvent[event], connhandle);
  
  if((event == BLE_EVENT_SCAN) ||           // If a BLE device was found during a passive or active scan -> 
     (event == BLE_EVENT_SCAN_RSP))
  {
    new sScan[TBLE_Scan];                   // Temporary memory for the scan response of a device

    /* Unpacks TBLE_Scan structure */
    rM2M_Pack(data, 0, sScan.addr_type, RM2M_PACK_GET|RM2M_PACK_U8);
    rM2M_GetPackedB(data, 1, sScan.addr, 6);
    rM2M_Pack(data, 7, sScan.rssi, RM2M_PACK_GET|RM2M_PACK_S8);
    rM2M_GetPackedB(data, 8, sScan.name, 32+1);
    rM2M_Pack(data, 41, sScan.msd_len, RM2M_PACK_GET|RM2M_PACK_U8);
    rM2M_GetPackedB(data, 42, sScan.msd, 32);

    BLE_EvScanned(sScan);                   // Calls function to process the scan response of a device
  }
  else if(event == BLE_EVENT_NOTIFY)        // Otherwise -> If the device has sent notification data  
  {
    new sNotify[TBLE_Notify];               // Temporary memory for the notification data received from a device

    /* Unpacks TBLE_Notify structure */
    rM2M_Pack(data, 0, sNotify.handle, RM2M_PACK_GET|RM2M_PACK_U16);
    rM2M_Pack(data, 2, sNotify.data_len, RM2M_PACK_GET|RM2M_PACK_U8);
    rM2M_GetPackedB(data, 3, sNotify.data, 32);

    BLE_EvNotify(sNotify);                  // Calls function to process the notification data received from a device
  }
  else if(event == BLE_EVENT_READ)          // Otherwise -> If data has been read ->
  {
    new sRead[TBLE_Read];                   // Temporary memory for the data read from a device

    /* Unpacks TBLE_Read structure */
    rM2M_Pack(data, 0, sRead.handle, RM2M_PACK_GET|RM2M_PACK_U16);
    rM2M_Pack(data, 2, sRead.offset, RM2M_PACK_GET|RM2M_PACK_U16);
    rM2M_Pack(data, 4, sRead.data_len, RM2M_PACK_GET|RM2M_PACK_U8);
    rM2M_GetPackedB(data, 5, sRead.data, 32);

    BLE_EvRead(sRead);                      // Calls function to process the data read from a device
  }
  else                                      // Otherwise -> Issues "Unknown event" via the console
    printf("Unknown event (%d)\r\n", event);
}
