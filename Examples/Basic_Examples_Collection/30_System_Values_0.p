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
 * Simple "System Values" Example
 *
 * Reads the last valid values for VBat, VUsb and Temp from the system and issues them every second via the console 
 *
 * Only compatible with rapidM2M M3
 * 
 * @version 20190619  
 */

/* Path for hardware-specific include file */
#include ".\rapidM2M IoT-Box\iotbox"

/* Forward declarations of public functions */
forward public Timer1s();                   // Called up 1x per sec. to read the last valid values for VBat, VUsb and Temp

/* Application entry point */
main()
{
  /* Temporary memory for the index of a public function and the return value of a function  */
  new iIdx, iResult;

  /* Initialisation of a 1 sec. timer used for the general program sequence
     - Determining the function index that should be executed 1x per sec.
     - Transferring the index to the system
     - in case of a problem the index and return value of the init function are issued by the console  */
  iIdx = funcidx("Timer1s");
  iResult = rM2M_TimerAdd(iIdx);
  if(iResult < OK)
    printf("rM2M_TimerAdd(%d) = %d\r\n", iIdx, iResult);
}

/* 1s Timer used to read the last valid values for VBat, VUsb and Temp from the system and issue them via the console   */
public Timer1s()
{
  new aSysValues[TIoTbox_SysValue];         // Temporary memory for the internal measurement values
  
  IoTbox_GetSysValues(aSysValues);          // Reads the last valid values for VBat, VUsb and Temp from the system 
                                            // The interval for determining these values is 1sec. and cannot be changed.        
  
  // Issues the last valid values for VBat, VUsb and Temp via the console
  printf("VBat = %dmV VUsb = %dmV Temp = %d[0,1 degree C]\r\n", aSysValues.VBat, aSysValues.VUsb, aSysValues.Temp);
}
