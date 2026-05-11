
/*KJ, May-sept 2021. 3-parameter incubator controller using PID. NB!!!!This sketch is dedicated for an esp32, namely esp32DevKitV1.!!! 
 * NOTE THAT analogWrite such as used on common Arduinos is NOT available in esp32, so this code is NOT portable to nano, etc.
 * the workaround used here is importing a library analogWrite.h that mimics the analogWrite.
 * */
//30Aug (//26 november )
#include "EasyNextionLibrary.h" //include the easiest library. Just 6 functions do it all
    // SEE: https://github.com/Seithan/EasyNextionLibrary
#include <Wire.h> //the library for I2C communication
#include <OneWire.h> //for the DS18B20 temp sensor
#include <DallasTemperature.h> //for DS18B20
#include <PID_v1.h>
#include <analogWrite.h> 
#include "Arduino.h"
#include "SPIFFS.h"
#include <MHZ16_uart.h> //CO2 sensor
#define TX 19 //set up pins for the third hardware uart
#define RX 18 //Arduino (Rx) <===> Adaptor's Green  Wire (Tx), Arduino (Tx) <===> Adaptor's Yellow Wire (Rx)
MHZ16_uart mySensor(RX, TX);

#define PIN_OutputTemp_PWM 32 //GPIO 32 = pin 6 of board. //Each of the 4 PIDs is hooked both to an analog output pin, and to a slow software PWM pin.
#define PIN_OutputTemp_Ana 33 //pin 7. //Both can be used at will, but not simultaneously
#define PIN_OutputCO2_PWM 25 //pin 8
#define PIN_OutputCO2_Ana 26 //pin 9
#define PIN_OutputHumid_PWM 27 //pin 10
#define PIN_OutputHumid_Ana 14 //pin 11
#define PIN_OutputLens_PWM 12 //pin 12
#define PIN_OutputLens_Ana 13 //pin 13

EasyNex myNex(Serial2); //connect to RX2/Tx2 so Serial0 remains available to upload to Arduino
const int oneWireBus = 4; //GPIO4 for the DS18B20
OneWire oneWire(oneWireBus);
DallasTemperature sensorLens(&oneWire);

int LED = 5;
unsigned long startMillis, systemStartMillis, currentMillis; //for time keeping
char fName[] = "/settings.csv"; //filename to store settings on flash

typedef struct { //this is easier than separate variables because C cannot return more that one value in a fn
  boolean graphPID;
  boolean graphPWM;
  boolean graphLens;
  boolean dataToComPort;
  boolean verboseToComPort;
  boolean alarms1;
  boolean alarms2;
  int plotInterval;
} structReadings;
structReadings readings; //declare readings as an instance of structReadings type.

typedef struct{
  double input;
  double setpoint;
  double output;
  boolean on_off;
  double Kp=2;
  double Ki=5;
  double Kd=1;  // aggresive and conservative settings are e.g. double aggKp=4, aggKi=0.2, aggKd=1; resp. double consKp=1, consKi=0.05, consKd=0.25;
  double PWM_period = 10000; //switching cycle
  double PWM_duty_cycle = 3000; //analog value = duty_cycle/period
  double PWM_start_Millis = 0;
  double PWM_min_duty_cycle = 150; // to prevent fast switching of relays and valves
  double PWM_out;
} structPIDdata;
structPIDdata T, H, C, L; //Temperature, Humidity, CO2, LensTemp

PID TempPID(&T.input, &T.output, &T.setpoint, T.Kp, T.Ki, T.Kd, DIRECT); //PIDs must be declared here with initial choice of settings
PID CO2PID(&C.input, &C.output, &C.setpoint, C.Kp, C.Ki, C.Kd, DIRECT);
PID HumidPID(&H.input, &H.output, &H.setpoint, H.Kp, H.Ki, H.Kd, DIRECT);
PID LensPID(&L.input, &L.output, &L.setpoint, L.Kp, L.Ki, L.Kd, DIRECT);

void setup() {
  #define HYT_ADDR 0x28   //I2C address for the HYT271 humidity/Temp sensor
  Wire.begin();
  sensorLens.begin();
  myNex.begin(115200);
  pinMode(LED_BUILTIN, OUTPUT); pinMode(PIN_OutputTemp_PWM, OUTPUT); pinMode(PIN_OutputCO2_PWM, OUTPUT); pinMode(PIN_OutputHumid_PWM, OUTPUT); pinMode(PIN_OutputLens_PWM, OUTPUT);
  Serial.begin(115200); //for communication to COM port PC
  startMillis=millis(); //to enable keeping time
  TempPID.SetMode(AUTOMATIC); HumidPID.SetMode(AUTOMATIC); CO2PID.SetMode(AUTOMATIC); LensPID.SetMode(AUTOMATIC);
  
  T.PWM_start_Millis=millis(); T.PWM_period=10000;   T.PWM_duty_cycle=100;   T.PWM_min_duty_cycle=300;//note: also in millis. so: NOT a %
  H.PWM_start_Millis=millis();H.PWM_period=10000;  H.PWM_duty_cycle=100;  H.PWM_min_duty_cycle=300;
  C.PWM_start_Millis=millis(); C.PWM_period=10000; C.PWM_duty_cycle=100; C.PWM_min_duty_cycle=300;  
  L.PWM_start_Millis=millis(); L.PWM_period=10000; L.PWM_duty_cycle=100; L.PWM_min_duty_cycle=300;  
  analogWriteResolution(PIN_OutputTemp_Ana, 10);//this is a wrapper for esp32 analogWrite 
  analogWriteResolution(PIN_OutputCO2_Ana, 10);
  analogWriteResolution(PIN_OutputHumid_Ana, 10);
  analogWriteResolution(PIN_OutputLens_Ana, 10);
  startMHZ16Sensor(); //initialize CO2 sensor. will cause a 10s warm-up delay
  
  initializeFS(); 
        //SPIFFS.remove("/settings.csv"); //to remove any old files
  listAllFiles();
  
  //ADD: here an if structure that saves a settingsfile if it doesn't exist.....................writeSettingsDataToFile(fName, readings, T, H, C, L); //if this is the first run ever, it must place a default settings file on disk or otherwise the read will crash
  readSettingsDataFromFile(fName, readings, T, H, C, L); //every restart, it picks up the most recent settings from disk
  writeSettingsDataToNextion(readings, T, H, C, L); //after every reading of settings, overwrite the settings on Nextion display  
  delay(100);
  
//T.Kp=20; T.Ki=4; T.Kd=30; //<<<<-----TEST SETTINGS
//TempPID.SetTunings(T.Kp, T.Ki, T.Kd, DIRECT); //grab the actual PID settings from the Arduino upon power-on
//CO2PID.SetTunings(C.Kp, C.Ki, C.Kd, DIRECT);
//HumidPID.SetTunings(H.Kp, H.Ki, H.Kd, DIRECT);
//LensPID.SetTunings(L.Kp, L.Ki, L.Kd, DIRECT);
}

void loop() {   // TODO   -- andere paginas vullen --autoCal the PIDs  --analog out for humidity with Servo

  //Section: get readings and dump them on Nextion display text fields
  getTempHumidFromHYT(T, H); //TempHum 
  C.input = 0.001*getCO2FromMHZ16(); //convert CO2 ppm to promille: 0.001x 
  sensorLens.requestTemperatures(); //lenstemp with DS18B20
  L.input = sensorLens.getTempCByIndex(0);
  myNex.writeStr("page0.txtTemp.txt", String(T.input));
  myNex.writeStr("page0.txtHumid.txt", String(H.input));
  myNex.writeStr("page0.txtCO2.txt", String(C.input));
  myNex.writeStr("page0.txtLens.txt", String(L.input));

//-------Section: PID controls
  TempPID.SetTunings(T.Kp, T.Ki, T.Kd, DIRECT); //grab the actual PID settings from the Arduino during run
  CO2PID.SetTunings(C.Kp, C.Ki, C.Kd, DIRECT);
  HumidPID.SetTunings(H.Kp, H.Ki, H.Kd, DIRECT);
  LensPID.SetTunings(L.Kp, L.Ki, L.Kd, DIRECT);
  TempPID.Compute();   HumidPID.Compute();   CO2PID.Compute(); LensPID.Compute();
  delay(100);

//-------Section: outputs. 
//this first set of outputs are analog values for T,C,H,L
  analogWrite(PIN_OutputTemp_Ana,4*T.output);// Note that this is not the common analogWrite from Ard nano etc, but a ESP32 lib replacement
  analogWrite(PIN_OutputCO2_Ana,4*C.output);
  analogWrite(PIN_OutputHumid_Ana,4*H.output);
  analogWrite(PIN_OutputLens_Ana,4*L.output);
        
//this second outputs are via the software PWM for slow switching. Both can be used at will and simultaneously.
//but to prevent relay/valve wear, CO2 and humidity are commonly used in slow PWM mode 
  T.PWM_duty_cycle=T.PWM_period * T.output/255; //convert ana to duty_cycle for PWM
  H.PWM_duty_cycle=H.PWM_period * H.output/255; 
  C.PWM_duty_cycle=C.PWM_period * C.output/255; 
  L.PWM_duty_cycle=L.PWM_period * L.output/255;   
  T.PWM_out=analog_to_PWM(T);
  H.PWM_out=analog_to_PWM(H);
  C.PWM_out=analog_to_PWM(C);
  L.PWM_out=analog_to_PWM(L);
  digitalWrite(PIN_OutputTemp_PWM, T.PWM_out);
  digitalWrite(PIN_OutputHumid_PWM, H.PWM_out);  
  digitalWrite(PIN_OutputCO2_PWM, C.PWM_out);
  digitalWrite(PIN_OutputLens_PWM, L.PWM_out);
  
  if (readings.dataToComPort){
    dumpDataOnSerial(readings.verboseToComPort); //generate some data on Com1 for logging or for test purposes
  }
  
//-------Section: plot every X seconds to the graph
  boolean plotNow = false;
  //settingsFromNextionToArduino(readings); //testing only. this function is normally called from the nextion via Trigger1()
  plotNow = intervalTimer(readings.plotInterval, startMillis);
  if (plotNow){
    if (readings.verboseToComPort){Serial.println("plots now");}
    int Hum = map((0.5+H.input), 0, 100, 0, 121); //make integer. Plot is 121 high
    int Temp = map((10*(T.input-0.3)), 100, 500, 0, 121); //make integer and scale for graph 10:50 in steps of 0.1 (10*T, 100, 500....)
//    Serial.print(T.input); Serial.print("  "); Serial.println(Temp); //<<<===========Testing
    int CO2 = map((0.5+C.input), 0, 200, 0, 121); //make integer and scale for graph 0:200 promille)   
    int Lens = map((10*(L.input-0.5)), 100, 500, 0, 121); //make integer and scale for graph 10:50  
    String addToWave=waveConcatenate(3,0,Temp); //first waveform has ID 3; 0 means first trace in that wafeform.
    myNex.writeStr(addToWave);
    addToWave=waveConcatenate(9,0,CO2); //second waveform has ID 9
    myNex.writeStr(addToWave);
    addToWave=waveConcatenate(13,0,Hum); //third waveform has ID 13
    myNex.writeStr(addToWave);
    
    if (readings.graphPID){ //this puts the PID output on the graph in gray
      int HumOut = map(H.output, 0, 255, 0, 121); //make integer. Plot is 121 high. analog output
      int TempOut = map(T.output, 0, 255, 0, 121); //make integer and scale for graph 10:50
      int CO2Out = map(C.output, 0, 255, 0, 121); //make integer and scale for graph 0:20
      addToWave=waveConcatenate(3,1,TempOut); //first waveform has ID 3 ; 1 means second trace in that wafeform.
      myNex.writeStr(addToWave);
      addToWave=waveConcatenate(9,1,CO2Out); //second waveform has ID 9
      myNex.writeStr(addToWave);
      addToWave=waveConcatenate(13,1,HumOut); //third waveform has ID 13
      myNex.writeStr(addToWave);      
    }
    if (readings.graphPWM){ //this puts the PWM output on the graph in greenish-gray
      addToWave=waveConcatenate(3,2,2+5*T.PWM_out); //first waveform has ID 3
      myNex.writeStr(addToWave);
      addToWave=waveConcatenate(9,2,2+5*C.PWM_out); //second waveform has ID 9
      myNex.writeStr(addToWave);
      addToWave=waveConcatenate(13,2,2+5*H.PWM_out); //third waveform has ID 13
      myNex.writeStr(addToWave);        
    }
    if (readings.graphLens){ //this puts the Lens output on the graph 
      addToWave=waveConcatenate(3,3,Lens); //first waveform has ID 3; 3 is reserved for Lens color
      myNex.writeStr(addToWave);
    }
  }

  //section: handle alarms levels 1 and 2.  
  myNex.writeNum("page0.nTemp.bco", 50712); //backgroundcolor to gray  
  myNex.writeNum("page0.nCO2.bco", 50712); //backgroundcolor to gray  
  myNex.writeNum("page0.nHumidity.bco", 50712); //backgroundcolor to gray
  if (readings.alarms1){ handleAlarms1(T, H, C);}
  if (readings.alarms2){ handleAlarms2(T, H, C);}

   
  myNex.NextionListen(); //thats all. It listens to trigger events which are called by a 4-byte code
  //from the nextion button or control. They can be trigger0() to trigger50() and are called as
  //printh 23 02 54 XX from the control in the Nextion, with XX=hex for 0 to 50
}


///////////BELOW follows the definition of the trigger functions that are executed by Nextion Controls as well as other functions

boolean intervalTimer(int pltInt, unsigned long &startMillis){   //reads out millies and returns True as soon as pltInt (interval) has elapsed
  currentMillis=millis();
  boolean ff=false;
  int timeSec=(currentMillis-startMillis)/1000; 
  //  Serial.print(startMillis);  Serial.print("   "); Serial.print(currentMillis); Serial.print("   "); Serial.print(pltInt); Serial.print("   "); Serial.println(timeSec);
  if (timeSec>=pltInt){   //Serial.println("yes!");
    startMillis=millis(); //this is not a very precise way of keeping time. Its a bit slower than intended
    ff=true;
  }
  return ff;
}

boolean analog_to_PWM(structPIDdata &PWM){ //it is here called PWM in the function because we only handle PWM parameters
  //KJ, June 2021. constructs a slow PWM signal based on period, duty_cycle and min_duty_cycle data in the input struct. 
  //to make more than one instance of the fn, just give it its own parameters:
  boolean out=0;
  int ff_current_Millis=millis();
  if (PWM.PWM_duty_cycle<PWM.PWM_min_duty_cycle){ //limit it to e.g. >300 or 0 tp prevent very short switches.
    PWM.PWM_duty_cycle=0;
  }
  if ((ff_current_Millis - PWM.PWM_start_Millis)<PWM.PWM_duty_cycle){
    out=1;
  }
  if ((ff_current_Millis - PWM.PWM_start_Millis)>PWM.PWM_period){
    PWM.PWM_start_Millis=ff_current_Millis;
  }
  return out;
}

String waveConcatenate(int waveformID, int traceNr, int value){
  String Tosend="add ";   Tosend += waveformID ;       //send the id of the block you want to add the value to
  Tosend += ",";  Tosend += traceNr;                   //Channel of that id, in this case channel 0 of the waveform
  Tosend += ",";  Tosend += value;     
  return(Tosend);
  }

void getTempHumidFromHYT(structPIDdata &T, structPIDdata &H){ //the & signals that it is passed by reference
  double humidity;
  double temperature;
  Wire.beginTransmission(HYT_ADDR);   // Begin transmission with HYT271 device on I2C bus
  Wire.requestFrom(HYT_ADDR, 4);      // Request 4 bytes, Read the bytes if they are available
                                      // two bytes are humidity, next two are temperature
  if(Wire.available() == 4) {                   
    int b1 = Wire.read();
    int b2 = Wire.read();
    int b3 = Wire.read();
    int b4 = Wire.read();
    Wire.endTransmission();           // End transmission and release I2C bus

    int rawHumidity = b1 << 8 | b2;     // combine humidity bytes and calculate humidity
    // compound bitwise to get 14 bit measurement first two bits are status/stall bit (see intro text)
    rawHumidity =  (rawHumidity &= 0x3FFF);
    humidity = 100.0 / pow(2,14) * rawHumidity;
    
    // combine temperature bytes and calculate temperature
    b4 = (b4 >> 2); // Mask away 2 least significant bits see HYT 221 doc
    int rawTemperature = b3 << 6 | b4;
    temperature = 165.0 / pow(2,14) * rawTemperature - 40;
    
    H.input=humidity; //transfer to output struct
    T.input=temperature;
  }
  else {
    Serial.println("Not enough bytes available on wire.");
  }
  blinkWait();    
}

void blinkWait() {
  digitalWrite(LED_BUILTIN, HIGH);   delay(250);   digitalWrite(LED_BUILTIN, LOW);   delay(700);
}

void startMHZ16Sensor(){
    mySensor.begin(RX,TX);
    Serial.println("Wait 10 seconds for the sensor to startup");
    delay(10000);
    Serial.println("START");  
}
long getCO2FromMHZ16(){
  long CO2ppm;
//  if ( !mySensor.isWarming()) //the more elaborate version is commented out because we only need the ppm value
//  {
//    Serial.print("CO2 Concentration is ");
    CO2ppm = mySensor.getPPM();
//    Serial.print(CO2ppm);
//    Serial.println("ppm");
//  }
//  else
//{
//    Serial.println("isWarming");
//  } 
  return CO2ppm;
}

void handleAlarms2(structPIDdata T, structPIDdata H, structPIDdata C) { //>>>>>>>>>>>>>>>>>>>>>>for now, no alarm on lens temp
  if (abs(T.input - T.setpoint) >2){
    myNex.writeNum("page0.nTemp.bco", 57792); //backgroundcolor to orange   
  }
  if (abs(H.input - H.setpoint) >15){
    myNex.writeNum("page0.nHumidity.bco", 57792);  
  }
  if (abs(C.input - C.setpoint) >2){
    myNex.writeNum("page0.nCO2.bco", 57792);  
  }
}

void handleAlarms1(structPIDdata T, structPIDdata H, structPIDdata C) {
  if (abs(T.input - T.setpoint) >1){
    myNex.writeNum("page0.nTemp.bco", 60910); //backgroundcolor to ored  
  }
  if (abs(H.input - H.setpoint) >5){
    myNex.writeNum("page0.nHumidity.bco", 60910); 
  }
  if (abs(C.input - C.setpoint) >1){
    myNex.writeNum("page0.nCO2.bco", 60910);   
  }
}

void dumpDataOnSerial(boolean dumpVerbose){
  if (dumpVerbose){
    Serial.println((currentMillis-systemStartMillis)/1000);
    Serial.print("in T: ");   Serial.print(T.input);   Serial.print(" Setp: ");   Serial.print(T.setpoint);   Serial.print(", output: ");   Serial.print(T.output); Serial.print(", PWM: "); Serial.println(T.PWM_out);
    Serial.print("in H: ");   Serial.print(H.input);   Serial.print(" Setp: ");   Serial.print(H.setpoint);   Serial.print(", output: ");   Serial.print(H.output); Serial.print(", PWM: "); Serial.println(H.PWM_out);
    Serial.print("in C: ");   Serial.print(C.input);   Serial.print(" Setp: ");   Serial.print(C.setpoint);   Serial.print(", output: ");   Serial.print(C.output); Serial.print(", PWM: "); Serial.println(C.PWM_out);
    Serial.print("in L: ");   Serial.print(L.input);   Serial.print(" Setp: ");   Serial.print(L.setpoint);   Serial.print(", output: ");   Serial.print(L.output); Serial.print(", PWM: "); Serial.println(L.PWM_out);
  }
  else{
    Serial.print((currentMillis-systemStartMillis)/1000); Serial.print(", ");
    Serial.print(T.input); Serial.print(", "); Serial.print(H.input); Serial.print(", "); Serial.print(C.input);  Serial.print(", ");Serial.print(L.input); Serial.println(" time-THCL");
  }
}
////////////////Triggers from Nextion to Arduino
void trigger1(){ //this function triggers an update of all settings from Nextion to Arduino but not to flash
  /* Write in the Touch Release Event of the button the command:    printh 23 02 54 01
   * Every time the button is pressed, the trigger1() function will run once   */
  settingsFromNextionToArduino(readings, T, H, C, L); //this indirect construction is necessary because Fn "trigger" doesn't seem to handle arguments
  Serial.println("running trigger1: updateFromNextion");
  errorseekFunction(readings, T, H, C, L); //*******
}

void trigger2(){ //this function triggers a dump of settings to COM port
//Write in the Touch Release Event of the button the command:    printh 23 02 54 02
  errorseekFunction(readings, T, H, C, L); //*******//this indirect construction is necessary because Fn "trigger" doesn't seem to handle arguments
  Serial.println("running trigger2: dump settings to Com Port");
}

void trigger3(){ //this function triggers a dump of settings to file (ESP32 flash drive)
// Every time the button is pressed, the trigger3() function will run once     
  writeSettingsDataToFile(fName, readings, T, H, C, L); 
  Serial.println("running trigger3: write settings to flash drive");
}

void trigger4(){ //this function triggers an reset to default settings and creates file, if needed
// Every time the button is pressed, the trigger2() function will run once     
  initializeSettingsFile(fName);
  readSettingsDataFromFile(fName, readings, T, H, C, L);
  writeSettingsDataToNextion(readings, T, H, C, L);     
  Serial.println("running trigger4: reset all settings (file, controller, nextion) to default");
}

void trigger5(){ //this function triggers a read of settings from file
// Every time the button is pressed, the trigger5() function will run once     
  readSettingsDataFromFile(fName, readings, T, H, C, L); //every restart, it picks up the most recent settings from disk
//  Serial.print("plotInterval "); Serial.println(readings.plotInterval);
  writeSettingsDataToNextion(readings, T, H, C, L); //after every reading of settings, overwrite the settings on Nextion display  
  Serial.println("running trigger5: update the settings from stored file");
}

////////////////>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>The next few fns take care of storing and retrieving settings on flashdrive.
void initializeFS(){
  Serial.println("Inizializing FS..."); //initialize FS once
  if (SPIFFS.begin()){
      Serial.println("done.");
  }else{ Serial.println("FS initializing failed."); }  
}

void listAllFiles(){
  //list all available files (if any) on the SPIFFS
  File root = SPIFFS.open("/");
  File file = root.openNextFile();
  while(file){
    Serial.print("FILE: ");
    Serial.println(file.name());
    file = root.openNextFile();
  }
  root.close();
  file.close();
}
//==>> NB!!!! because the Nextion doesn't handle floats, adjustable 'floaf' numeric fields (12 PID K parameters) are passed as %, 
//==>> i.e. Ki=1000% means Ki=10 for the PID. This means that ONLY THOSE must be divided by 100 when retrieving from Nextion, and multiplied by 100
//==>> when sending to Nextion. This makes K parameters standard with 2 decimals

void settingsFromNextionToArduino(structReadings &readings, structPIDdata &T, structPIDdata &H, structPIDdata &C, structPIDdata &L){ //read out a numbr of settings from Nextion fields
  readings.plotInterval = myNex.readNumber("page0.n1.val");
  readings.graphPID=myNex.readNumber("page1.cGraphPID.val");
  readings.graphPWM=myNex.readNumber("page1.cGraphPWM.val");  
  readings.graphLens=myNex.readNumber("page1.cGraphLens.val");
  readings.dataToComPort=myNex.readNumber("page1.cDataToCom.val");
  readings.verboseToComPort=myNex.readNumber("page1.cVerboseToCom.val"); 
  readings.alarms1=myNex.readNumber("page1.cAlarms1.val");
  readings.alarms2=myNex.readNumber("page1.cAlarms2.val");    
  T.setpoint=myNex.readNumber("page0.nTemp.val");
  H.setpoint=myNex.readNumber("page0.nHumidity.val");
  C.setpoint=myNex.readNumber("page0.nCO2.val")/10;
  L.setpoint=myNex.readNumber("page0.nLens.val");
  T.on_off=myNex.readNumber("page0.sw0.val");
  C.on_off=myNex.readNumber("page0.sw1.val");
  H.on_off=myNex.readNumber("page0.sw2.val");  
  L.on_off=myNex.readNumber("page0.sw3.val");
  T.Kp = (myNex.readNumber("page1.nTKp.val"))/100;
  T.Ki = myNex.readNumber("page1.nTKi.val")/100;
  T.Kd = myNex.readNumber("page1.nTKd.val")/100; 
  H.Kp = myNex.readNumber("page1.nHKp.val")/100; 
  H.Ki = myNex.readNumber("page1.nHKi.val")/100;
  H.Kd = myNex.readNumber("page1.nHKd.val")/100;
  C.Kp = myNex.readNumber("page1.nCKp.val")/100; 
  C.Ki = myNex.readNumber("page1.nCKi.val")/100; 
  C.Kd = myNex.readNumber("page1.nCKd.val")/100;
  L.Kp = myNex.readNumber("page1.nLKp.val")/100;
  L.Ki = myNex.readNumber("page1.nLKi.val")/100; 
  L.Kd = myNex.readNumber("page1.nLKd.val")/100;   
}

void readSettingsDataFromFile(char* fName, structReadings &readings, structPIDdata &T, structPIDdata &H, structPIDdata &C, structPIDdata &L){
//not really the most elegant solution ever seen, but if works for the moment...
  File testFile = SPIFFS.open(fName, "r"); //open file again and read data into var
  if (testFile){
    Serial.println("Read file content OK!");
    // File derives from Stream so you can use all Stream methods like readBytes, findUntil, parseInt, println etc
    String one1 = "1"; //this, together with the comparison in next statements, makes sure it is a Boolean
    String fileData =testFile.readStringUntil(','); //reads to , just to skip to start of settings   
    T.on_off = one1 == testFile.readStringUntil(',');  
    H.on_off = one1 == testFile.readStringUntil(',');  C.on_off = one1 == testFile.readStringUntil(','); 
    L.on_off = one1 == testFile.readStringUntil(','); 
    readings.graphPID =  one1 == testFile.readStringUntil(','); readings.graphPWM =  one1 == testFile.readStringUntil(','); 
    readings.graphLens =  one1 == testFile.readStringUntil(',');  readings.dataToComPort =  one1 == testFile.readStringUntil(','); 
    readings.verboseToComPort =  one1 == testFile.readStringUntil(','); readings.alarms1 =  one1 == testFile.readStringUntil(',');  
    readings.alarms2 =  one1 == testFile.readStringUntil(','); 
    readings.plotInterval = testFile.readStringUntil(',').toInt(); 
    T.setpoint = testFile.readStringUntil(',').toDouble();  H.setpoint = testFile.readStringUntil(',').toDouble();  
    C.setpoint = testFile.readStringUntil(',').toDouble();  L.setpoint = testFile.readStringUntil(',').toDouble();  
    T.Kp = testFile.readStringUntil(',').toDouble();  T.Ki = testFile.readStringUntil(',').toDouble(); T.Kd = testFile.readStringUntil(',').toDouble();    
    H.Kp = testFile.readStringUntil(',').toDouble();  H.Ki = testFile.readStringUntil(',').toDouble(); H.Kd = testFile.readStringUntil(',').toDouble();    
    C.Kp = testFile.readStringUntil(',').toDouble();  C.Ki = testFile.readStringUntil(',').toDouble(); C.Kd = testFile.readStringUntil(',').toDouble();    
    L.Kp = testFile.readStringUntil(',').toDouble();  L.Ki = testFile.readStringUntil(',').toDouble(); L.Kd = testFile.readStringUntil(',').toDouble();                          
    fileData=testFile.readString(); //read the rest if it exists
    testFile.close();
  }else{ Serial.println("Problem on read file!"); } 
}

void writeSettingsDataToFile(char* fName, structReadings &readings, structPIDdata &T, structPIDdata &H, structPIDdata &C, structPIDdata &L){
  File testFile = SPIFFS.open(fName, "w"); //create file once;
  if (testFile){ //write data to file &close file
      testFile.print("Stores-subsequently:-Stemp-SHumid-SCO2-SLens-SPIDOut-SPWMOut-SLensOut-SData-SVerbose-SAlarm1-SAlarm2-plotspeed-setTemp-setHumid-setCO2-setLens-and-Kp&Ki&Kd-for-T&H&C&L!!");
      //================== concatenate all settings
      String ToSend=","; ToSend+=String(T.on_off); ToSend +=","; ToSend+=String(H.on_off); ToSend +=","; ToSend+=String(C.on_off); ToSend +=","; ToSend+=String(L.on_off);
      ToSend +=","; ToSend+=String(readings.graphPID); ToSend +=","; ToSend+=String(readings.graphPWM); ToSend +=","; ToSend+=String(readings.graphLens);
      ToSend +=","; ToSend+=String(readings.dataToComPort); ToSend +=","; ToSend+=String(readings.verboseToComPort); ToSend +=","; ToSend+=String(readings.alarms1); ToSend +=","; ToSend+=String(readings.alarms2);
      ToSend +=","; ToSend+=String(readings.plotInterval); ToSend +=","; ToSend+=String(T.setpoint); ToSend +=","; ToSend+=String(H.setpoint);
      ToSend +=","; ToSend+=String(C.setpoint); ToSend +=","; ToSend+=String(L.setpoint); 
      ToSend +=","; ToSend+=String(T.Kp); ToSend +=","; ToSend+=String(T.Ki); ToSend +=","; ToSend+=String(T.Kd);
      ToSend +=","; ToSend+=String(H.Kp); ToSend +=","; ToSend+=String(H.Ki); ToSend +=","; ToSend+=String(H.Kd);
      ToSend +=","; ToSend+=String(C.Kp); ToSend +=","; ToSend+=String(C.Ki); ToSend +=","; ToSend+=String(C.Kd);
      ToSend +=","; ToSend+=String(L.Kp); ToSend +=","; ToSend+=String(L.Ki); ToSend +=","; ToSend+=String(L.Kd);
      //============
      testFile.print(ToSend); //and write them to file
      testFile.close();
      Serial.println("Write file content OK!");
  }else{
      Serial.println("Problem on create file!");
  }   
  Serial.print("  write T setpoint = "); Serial.println(T.setpoint);
}

void initializeSettingsFile(char* fName){
  File testFile = SPIFFS.open(fName, "w"); //create file once;
  if (testFile){ //write data to file &close file
    String ToSend="Stores-subsequently:-Stemp-SHumid-SCO2-SLens-SPIDOut-SPWMOut-SLensOut-SData-SVerbose-SAlarm1-SAlarm2-plotspeed-setTemp-setHumid-setCO2-setLens-and-Kp&Ki&Kd-for-T&H&C&L!!";
    ToSend+=",1,1,1,0,1,1,1,1,0,1,1,2,37,85,5,37,2,5,1,2,5,1,2,5,1,2,5,3";
    testFile.print(ToSend); //and write them to file   
    Serial.println("Settings file initialized. Now optionally reset hardware!");
    testFile.close();
  }else{
    Serial.println("Problem on create file!");
  }   
}

void writeSettingsDataToNextion(structReadings &readings, structPIDdata &T, structPIDdata &H, structPIDdata &C, structPIDdata &L){
  myNex.writeNum("page0.sw0.val", T.on_off);   myNex.writeNum("page0.sw1.val", H.on_off);
  myNex.writeNum("page0.sw2.val", C.on_off);  myNex.writeNum("page0.sw3.val", L.on_off);
  myNex.writeNum("page1.cGraphPID.val", readings.graphPID);   myNex.writeNum("page1.cGraphPWM.val", readings.graphPWM);
  myNex.writeNum("page1.cGraphLens.val", readings.graphLens);   myNex.writeNum("page1.cDataToCom.val", readings.dataToComPort);
  myNex.writeNum("page1.cVerboseToCom.val", readings.verboseToComPort);   myNex.writeNum("page1.cAlarms1.val", readings.alarms1);    
  myNex.writeNum("page1.cAlarms2.val", readings.alarms2);  myNex.writeNum("page0.n1.val", readings.plotInterval);          
  myNex.writeNum("page0.nTemp.val", T.setpoint);  myNex.writeNum("page0.nHumidity.val", H.setpoint);
  myNex.writeNum("page0.nCO2.val", C.setpoint*10);   myNex.writeNum("page0.nLens.val", L.setpoint); 
  myNex.writeNum("page1.nTKp.val", T.Kp*100);  myNex.writeNum("page1.nTKi.val", H.Ki*100);
  myNex.writeNum("page1.nTKd.val", C.Kd*100);  myNex.writeNum("page1.nHKp.val", L.Kp*100); 
  myNex.writeNum("page1.nHKi.val", T.Ki*100);  myNex.writeNum("page1.nHKd.val", H.Kd*100);
  myNex.writeNum("page1.nCKp.val", C.Kp*100);  myNex.writeNum("page1.nCKi.val", L.Ki*100); 
  myNex.writeNum("page1.nCKd.val", T.Kd*100);  myNex.writeNum("page1.nLKp.val", H.Kp*100);
  myNex.writeNum("page1.nLKi.val", C.Ki*100);  myNex.writeNum("page1.nLKd.val", L.Kd*100); 
  Serial.println("writing settings to Nextion OK");
}

void errorseekFunction(structReadings &readings, structPIDdata &T, structPIDdata &H, structPIDdata &C, structPIDdata &L){ //to be invoked when things are soupy
  Serial.println("");
  Serial.println("Settings as reported by file: ");
  File testFile = SPIFFS.open(fName, "r");  
  String fileData =testFile.readStringUntil(','); //reads to ,
  Serial.println(fileData);
  fileData=testFile.readStringUntil('@'); //to the EOF
  Serial.println(fileData);
  testFile.close();   

  Serial.println("Settings as reported by Arduino: ");  
  Serial.print(T.on_off); Serial.print(" "); Serial.print(H.on_off); Serial.print(" "); Serial.print(C.on_off); Serial.print(" "); 
  Serial.print(L.on_off); Serial.print(" ");   Serial.print(readings.graphPID); Serial.print(" "); Serial.print(readings.graphPWM); 
  Serial.print(" "); Serial.print(readings.graphLens);Serial.print(" "); Serial.print(readings.dataToComPort); Serial.print(" "); 
  Serial.print(readings.verboseToComPort);Serial.print(" "); Serial.print(readings.alarms1); Serial.print(" "); Serial.print(readings.alarms2);
  Serial.print(" "); Serial.print(readings.plotInterval); Serial.print(" "); Serial.print(T.setpoint); Serial.print(" ");   
  Serial.print(H.setpoint); Serial.print(" ");  Serial.print(C.setpoint); Serial.print(" ");   Serial.print(L.setpoint); Serial.print(" ");  
  Serial.print(T.Kp); Serial.print(" ");   Serial.print(T.Ki); Serial.print(" ");   Serial.print(T.Kd); Serial.print(" "); 
  Serial.print(H.Kp); Serial.print(" ");   Serial.print(H.Ki); Serial.print(" ");   Serial.print(H.Kd); Serial.print(" "); 
  Serial.print(C.Kp); Serial.print(" ");   Serial.print(C.Ki); Serial.print(" ");   Serial.print(C.Kd); Serial.print(" "); 
  Serial.print(L.Kp); Serial.print(" ");   Serial.print(L.Ki); Serial.print(" ");   Serial.println(L.Kd);
 
  Serial.println("Settings as reported by Nextion (K parameters in %): ");    
  Serial.print(myNex.readNumber("page0.sw0.val"));  Serial.print(" "); Serial.print(myNex.readNumber("page0.sw1.val"));  Serial.print(" ");
  Serial.print(myNex.readNumber("page0.sw2.val"));  Serial.print(" "); Serial.print(myNex.readNumber("page0.sw3.val"));  Serial.print(" ");
  Serial.print(myNex.readNumber("page1.cGraphPID.val"));  Serial.print(" ");  Serial.print(myNex.readNumber("page1.cGraphPWM.val"));  Serial.print(" ");  
  Serial.print(myNex.readNumber("page1.cGraphLens.val"));  Serial.print(" ");  Serial.print(myNex.readNumber("page1.cDataToCom.val"));  Serial.print(" ");
  Serial.print(myNex.readNumber("page1.cVerboseToCom.val"));  Serial.print(" ");  Serial.print(myNex.readNumber("page1.cAlarms1.val"));  Serial.print(" ");
  Serial.print(myNex.readNumber("page1.cAlarms2.val"));  Serial.print(" ");  Serial.print( myNex.readNumber("page0.n1.val"));  Serial.print(" ");
  Serial.print(myNex.readNumber("page0.nTemp.val"));  Serial.print(" "); Serial.print(myNex.readNumber("page0.nHumidity.val"));  Serial.print(" ");
  Serial.print(myNex.readNumber("page0.nCO2.val"));  Serial.print(" ");  Serial.print(myNex.readNumber("page0.nLens.val"));  Serial.print(" ");
  Serial.print(myNex.readNumber("page1.nTKp.val"));  Serial.print(" ");  Serial.print(myNex.readNumber("page1.nTKi.val"));  Serial.print(" ");
  Serial.print(myNex.readNumber("page1.nTKd.val"));  Serial.print(" ");  Serial.print(myNex.readNumber("page1.nHKp.val"));  Serial.print(" "); 
  Serial.print(myNex.readNumber("page1.nHKi.val"));  Serial.print(" ");  Serial.print(myNex.readNumber("page1.nHKd.val"));  Serial.print(" ");
  Serial.print(myNex.readNumber("page1.nCKp.val"));  Serial.print(" ");  Serial.print(myNex.readNumber("page1.nCKi.val"));  Serial.print(" "); 
  Serial.print(myNex.readNumber("page1.nCKd.val"));  Serial.print(" ");  Serial.print(myNex.readNumber("page1.nLKp.val"));  Serial.print(" ");
  Serial.print(myNex.readNumber("page1.nLKi.val"));  Serial.print(" ");  Serial.println(myNex.readNumber("page1.nLKd.val"));  
  Serial.println("");
}
