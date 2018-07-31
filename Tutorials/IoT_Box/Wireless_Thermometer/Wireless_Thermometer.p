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

/* Pfad für das hardwarespezifische Include-File */
#include ".\rapidM2M IoT-Box\iotbox"

/* Forward Deklarationen der öffentlichen Funktionen */
forward public Timer1s();                   // für den Programmablauf, wird 1x pro sec. aufgerufen
forward public ReadConfig(cfg);             // wird bei Änderung eines der Konfigblöcke aufgerufen 
forward public KeyChanged(iKeyState);       // wird beim Drücken und Loslassen der Taste aufgerufen

/* Standardwerte für die Initialisierung der Konfiguration */   
const
{
  ITV_RECORD        = 1 * 60,               // Aufzeichnungsintervall [sec.], default 1 min
  ITV_TRANSMISSION  = 1 * 60 * 60,          // Übertragungsintervall [sec.], default 60 min
  TXMODE            = RM2M_TXMODE_TRIG,     // Verbindungsart, default "Intervall" 

  DEFAULT_COLOR     = 0x00008ECF,           // Farbe der LED
}

/* Größen- und Indexangaben für die Konfigurationsblöcke und den Messdatenblock */
const
{
  CFG_BASIC_INDEX = 0,                      // In Konfigblock 0 befindet sich die Basiskonfig
  CFG_BASIC_SIZE = 9,                       // Aufzeichungsintv.(u32) + Übertragungsintv.(u32) + 
                                            // Verbindungsart (u8)

  HISTDATA_SIZE = 3 * 2 + 1,                // 3 Kanäle (s16) + "Split-tag" (u8)
}

/* Globale Variablen zur Aufnahme der aktuellen Konfiguration */
static iRecItv;                             // aktuelles Aufzeichnungsintervall [sec.]
static iTxItv;                              // aktuelles Übertragungsintervall [sec.]
static iTxMode;                             // aktuelle Verbindungsart (0 = Intervall, 
                                            // 1 = Wakeup, 2 = Online)   
                                            
/* Globale Variablen für die verbleibende Zeit bis zum Auslösen bestimmter Aktionen */
static iRecTimer;                           // sec. bis zur nächsten Aufzeichnung
static iTxTimer;                            // sec. bis zur nächsten Übertragung

/* application entry point */
main()
{
  /* Zwischenspeicher für den Index einer öffentlichen Funktion und den Rückgabewert einer Funktion     */  
  new iIdx, iResult;                         
  
  /* Initialisierung des Tasters -> Auswertung durch das Script aktiviert  
     - Index der Funktion, die beim Drücken und Loslassen der Taste aufgerufen werden soll, ermitteln 
     - Index ans System übergeben sowie mitteilen, dass die Steuerung der Taste durch das Script erfolgt
     - Index sowie Rückgabewert der Init-Funktion werden über die Console ausgegeben                    */
  iIdx = funcidx("KeyChanged");                        
  iResult = Switch_Init(SWITCH_MODE_SCRIPT, iIdx);     
  printf("Switch_Init(%d) = %d\r\n", iIdx, iResult);   
  
  /* Initialisierung der LED -> Ansteuerung durch das Script aktiviert */  
  Led_Init(LED_MODE_SCRIPT);
   
  /* Initialisierung eines 1sec. Timers, der für den generellen Programmablauf verwendet wird
     - Index der Funktion, die 1x pro sec. ausgeführt werden soll, ermitteln 
     - Index ans System übergeben
     - Index sowie Rückgabewert der Funktion zum Erzeugen des Timers werden über die Console ausgegeben */
  iIdx = funcidx("Timer1s");
  iResult = rM2M_TimerAdd(iIdx);
  printf("rM2M_TimerAdd(%d) = %d\r\n", iIdx, iResult);

  /* Festlegen der Funktion, die bei einer Änderung eines Konfigblockes aufgerufen werden soll
     - Index der Funktion, bei Änderung eines der Konfigblöcke aufgerufen, ermitteln 
     - Index ans System übergeben
     - Index sowie Rückgabewert der Init-Funktion werden über die Console ausgegeben                    */
  iIdx = funcidx("ReadConfig");
  iResult = rM2M_CfgOnChg(iIdx);
  printf("rM2M_CfgOnChg(%d) = %d\r\n", iIdx, iResult);

  /* Auslesen der Basiskonfiguration. Ist der Konfigblock 0 noch leer (erster Programmstart), wird die
     Basiskonfiguration mit Standardwerten initialisiert.                                               */
  ReadConfig(CFG_BASIC_INDEX);
  
  /* Durch das Setzen der Zähler auf 0 wird sofort eine Übertragung sowie eine Aufzeichnung ausgelöst. 
     Das 0 setzen könnte auch unterlassen werden, da in PAWN alle Variablen beim Anlegen mit 0 
     initialisiert werden. Es wurde an dieser Stelle zum besseren Verständnis jedoch durchgeführt.      */
  iTxTimer  = 0;
  iRecTimer = 0;

  /* Setzen der Verbindungsart */
  rM2M_TxSetMode(iTxMode);
}

/* 1sec. Timer, wird für den generellen Programmablauf verwendet */
public Timer1s()
{
  Handle_Led();                             // Steuerung der LED  
  Handle_Transmission();                    // Steuerung der Übertragung
  Handle_Record();                          // Steuerung der Aufzeichnung
}

/* Funktion für die Steuerung der LED */
Handle_Led()
{
  new iTxStatus;                            // Zwischenspeicher für den Verbindungsstatus 
  
  iTxStatus = rM2M_TxGetStatus();           // Akuellen Verbindungsstatus vom System lesen 
  
  if(iTxStatus & RM2M_TX_ACTIVE)            // Wenn gerade eine GPRS-Verbindung besteht ->
  {
    Led_Off();                              // LED ausschalten
    Led_On(DEFAULT_COLOR);                  // LED einschalten (Default LED-Farbe)
  }
  /* Wenn gerade ein Verbindungsaufbau durchgeführt wird oder die Wartezeit bis zum Retry läuft -> */
  else if(iTxStatus & (RM2M_TX_STARTED|RM2M_TX_RETRY)) 
  {
    Led_Off();                              // LED ausschalten
    Led_Flicker(0, DEFAULT_COLOR);          // LED flackert dauerhaft (Default LED-Farbe)
  }
  else if( iTxStatus & RM2M_TX_FAILED)      // Wenn der letzte Verbindungsaufbau fehlgeschlagen ist ->
  {
    Led_Off();                              // LED ausschalten
    Led_Blink(0, 0x00FF0000);               // LED blinkt dauerhaft rot 
  }
  else                                      // Andernfalls ->
    Led_Off();                              // LED ausschalten
}

/* Funktion für die Erzeugung des Übertragungsintervalls */
Handle_Transmission()
{
  iTxTimer--;                               // Zähler mit den sec. bis zur nächsten Übertragung reduzieren 
  if(iTxTimer <= 0)                         // Wenn der Zähler abgelaufen ist -> 
  {
    rM2M_TxStart();                         // Eine Verbindung zum Server herstellen 
    iTxTimer = iTxItv;                      // Zählervar. auf akt. Übertragungsintv. [sec.] zurücksetzen 
  }
}

/* Funktion für die Aufzeichnung der Daten */
Handle_Record()
{
  /* Zwischenspeicher in dem der zu speichernde Datensatz zusammengesetzt wird. */   
  new aRecData{HISTDATA_SIZE};              
  
  iRecTimer--;                              // Zähler mit sec. bis zur nächsten Aufzeichnung reduzieren 
  if(iRecTimer <= 0)                        // Wenn der Zähler abgelaufen ist -> 
  {
    new aSysValues[TIoTbox_SysValue];       // Zwischenspeicher für die int. Messwerte (VBat, VUsb, Temp)
    
    IoTbox_GetSysValues(aSysValues);        // Auslesen der aktuellen int. Messwerte (VBat, VUsb, Temp)
    
    /* Zusammensetzen des zu speichernden Datensatzes im Zwischenspeicher "aRecData"
       - Das erste Byte(Postion 0 im Array "aRecData") wird auf 0 gesetzt damit der Server den Datensatz, 
         wie beim Entwurf des Connectors angegeben, beim Empfangen in Messdatenkanal 0 kopiert
       - Auf Postion 1-2 wird die Batteriespannung (VBat) kopiert. Datentyp: s16
       - Auf Postion 3-4 wird die USB-Ladespannung (VUsb) kopiert. Datentyp: s16
       - Auf Postion 5-6 wird die Temperatur (Temp) kopiert. Datentyp: s16                              */
    aRecData{0} = 0;                        // "Split-tag" 
    rM2M_Pack(aRecData,  1,   aSysValues.VBat, RM2M_PACK_BE + RM2M_PACK_S16);
    rM2M_Pack(aRecData,  3,   aSysValues.VUsb, RM2M_PACK_BE + RM2M_PACK_S16);
    rM2M_Pack(aRecData,  5,   aSysValues.Temp, RM2M_PACK_BE + RM2M_PACK_S16);

    /* Zusammengesetzten Datensatz ans System zur Aufzeichnung übergeben */
    rM2M_RecData(0, aRecData, HISTDATA_SIZE);

    iRecTimer = iRecItv;                    // Zählervariable auf akt. Aufzeichnungsintv. zurücksetzen 

    /* Aktuelle Messwerte über die Console ausgegeben */
    printf("Vb:%d Vu:%d Ti:%d\r\n",aSysValues.VBat, aSysValues.VUsb, aSysValues.Temp);
  }
}

/* Funktion, die das Auslösen einer Übertragung durch einen Tastendruck ermöglicht */
public KeyChanged(iKeyState)
{
  printf("K:%d\r\n", iKeyState);            // Aktion über die Console ausgeben (0=Loslassen, 1=Drücken)

  if(!iKeyState)                            // Wenn die Taste losgelassen wurde ->
  {
    /* Zählvariable der sec. bis zur nächsten Übertragung auf 0 setzen. Dadurch wird beim nächsten Aufruf 
       der Funktion "Handle_Transmission" durch die Funktion "Timer1s" eine Übertragung ausgelöst.      */
    iTxTimer = 0;                           
  }                                              
}

/* Funktion, die es ermöglicht auf eine vom Server empfangene, geänderte Konfiguration zu reagieren */
public ReadConfig(cfg)
{
  // Wenn es sich bei der geänderten Konfiguration um die Basiskonfig handelt -> */          
  if(cfg == CFG_BASIC_INDEX)                
  {
    new aData{CFG_BASIC_SIZE};              // Zwischenspeicher für die vom System gelesene Basiskonfig
    new iSize;                              // Zwischenspeicher für die Größe der Basiskonfig in Bytes
    new iTmp;                               // Zwischenspeicher für einen Parameter der Basiskonfig 
  
    /* Basiskonfig vom System lesen und in den Zwischenspeicher kopieren. Anschließend wird die 
       Nummer des Konfigblocks und der Rückgabewert der Lesefunktion (Anzahl der Bytes bzw. Fehlercode) 
       über die Console ausgegeben                                                                      */ 
    iSize = rM2M_CfgRead(cfg, 0, aData, CFG_BASIC_SIZE);
    printf("Cfg %d size = %d\r\n", cfg, iSize);  
 

    /* Wenn die Anzahl der gelesenen Bytes unter der Größe der Basiskonfig liegt ->
      Info: Fehlercodes sind negativ                                                                    */
    if(iSize < CFG_BASIC_SIZE)              
    {
      /* Der folgende Block kopiert zunächst die Default-Werte in den Zw.speicher für die gelesene  
         Basiskonfig und setzt dann den Zw.speicher für die Größe der Basiskonfig auf die aktuelle 
         Größe. Dadurch wird das folgende "IF" sowohl beim Neuinitialisieren als auch bei empfangenen 
         Änderungen durchlaufen. Müssen für einzelne Parameter spezielle Aktionen ausgeführt werden, 
         ist es so nicht notwendig dies für beide Fälle getrennt zu implementieren.                     */
      iTmp = ITV_RECORD;
      rM2M_Pack(aData, 0, iTmp,  RM2M_PACK_BE + RM2M_PACK_U32);
      iTmp = ITV_TRANSMISSION;
      rM2M_Pack(aData, 4, iTmp,   RM2M_PACK_BE + RM2M_PACK_U32);
      iTmp = TXMODE;
      rM2M_Pack(aData, 8, iTmp,  RM2M_PACK_BE + RM2M_PACK_U8);
      iSize = CFG_BASIC_SIZE;
      print("created new Config #0\r\n");
    }


    /* Wenn die Anzahl der gelesenen Bytes mindestens der Größe der Basiskonfig entspricht -> */
    if(iSize >= CFG_BASIC_SIZE)
    {
      /* Aufzeichnungsintervall(u32, Big Endian) auf Postion 0-3 aus dem Zw.speicher für die gelesene 
         Basiskonfig in den Zw.speicher für einen Parameter kopieren                                    */  
      rM2M_Pack(aData, 0, iTmp,  RM2M_PACK_BE + RM2M_PACK_U32 + RM2M_PACK_GET);
      if(iTmp != iRecItv)    // Wenn der empfangene Wert nicht jenem der globalen Variablen entspricht ->
      {
        printf("iRecItv changed to %d s\r\n", iTmp);  // empfangenen Wert über die Console ausgeben
        iRecItv = iTmp;                               // empfangenen Wert in globale Variable übernehmen 
      }
      
      /* Übertragungsintervall(u32, Big Endian) auf Postion 4-7 aus dem Zw.speicher für die gelesene 
         Basiskonfig in den Zw.speicher für einen Parameter kopieren                                    */
      rM2M_Pack(aData, 4, iTmp,  RM2M_PACK_BE + RM2M_PACK_U32 + RM2M_PACK_GET);
      if(iTmp != iTxItv)     // Wenn der empfangene Wert nicht jenem der globalen Variablen entspricht ->
      {
        printf("iTxItv changed to %d s\r\n", iTmp);   // empfangenen Wert über die Console ausgeben
        iTxItv = iTmp;                                // empfangenen Wert in globale Variable übernehmen 
      }

      /* Verbindungsart(u8) auf Postion 8 aus dem Zw.speicher für die gelesene Basiskonfig in den 
         Zw.speicher für einen Parameter kopieren                                                        */
      rM2M_Pack(aData, 8, iTmp,  RM2M_PACK_BE + RM2M_PACK_U8 + RM2M_PACK_GET);
      if(iTmp != iTxMode)    // Wenn der empfangene Wert nicht jenem der globalen Variablen entspricht ->
      {
        rM2M_TxSetMode(iTmp);                         // Verbindungsart auf den empfangenen Wert setzen
        printf("iTxMode changed to %d\r\n", iTmp);    // empfangenen Wert über die Console ausgeben
        iTxMode = iTmp;                               // empfangenen Wert in globale Variable übernehmen 
      }
    }
  }
}
