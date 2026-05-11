/* Auto Shutter V2 for the Leica Lamp
 * The button of the lamphouse has been connected to the outside via two bananaplugs
 * A solid state relais can short the bananaplugs and activate the lamp
 * The relais is connected to Pin 3
 * An external trigger is connected to pin 2
 * The microscope frame trigger is connected to pin ??
 * It sets the input high when a frame is being taken
 * 
 * Buttons give the following input on analog 0
 * right - 0
 * up - 99
 * down - 255
 * left - 410
 * select - 640
 * idle - 1023
 * switchpoints: 50 177 333 525 832
 */

 
// include the library code:
#include <LiquidCrystal.h>
#define debug false
#define triggerInPin 2  //Digital pin 2
#define frameInPin 11
#define outPin 3    //Digital pin 3
#define NR_OF_SETTINGS 7

byte GUIMode; 
boolean firstRun;
byte updateDisplay; //0=no, 1=yes with delay, 2=yes without delay
byte button;
int currentSettings[NR_OF_SETTINGS];
int selectedSetting;
unsigned long viewStartTime;
unsigned long storeStartTime;

boolean lightOn;    //is the light on?
boolean inputHigh;
unsigned long lightStartTime;
unsigned long lightStopTime;
unsigned long frameLowTime;
boolean framePin;   //value of the framepin
boolean triggerPin; //value of the triggerPin
boolean reachedFrame;
int numberOfFrames;
int delayTime;

// initialize the library with the numbers of the interface pins
LiquidCrystal lcd(8, 9, 4, 5, 6, 7);

void setup() {
  pinMode(triggerInPin,INPUT_PULLUP);
  pinMode(frameInPin,INPUT);
  pinMode(outPin,OUTPUT);
  GUIMode = 0;                      //0 Rest ; 1 View ; 2 Change ; 3 Store
  selectedSetting=NR_OF_SETTINGS-1; //can be changed in View GUImode to move between settings 6 = Reset Framecounter
  currentSettings[0] = 1000;   //ms pulsewidth
  currentSettings[1] = 0;      //ShutterMode 0 Triggered ; 1 Continous ; 2 FrameSync
  currentSettings[2] = 20;     //Total period
  currentSettings[3] = 20;     //Total frames
  currentSettings[4] = 10;     //Flash frame
  currentSettings[5] = 100;     //Flash frame duration (ms)
  currentSettings[6] = 0;      //Reset (not used)
  numberOfFrames=0;
  delayTime=200; //time to increase/decrease setting value
  lightStopTime=millis();
  framePin = false;
  lightOn = false;
  triggerPin = false;
  // set up the LCD's number of columns and rows: 
  lcd.begin(16, 2);
  // Print a message to the LCD.
  lcd.print("Welcome");
  firstRun=true;
}

byte getButton(int input){
  if (input<50){ //right
    return 0;
  }else if (input<177){ //up
    return 2;
  }else if (input<333){ //down
    return 3;
  }else if (input<525){ //left
    return 1;
  }else if (input<832){ //select
    return 4;
  }else{ //idle
    return 5;
  }
}

void loop() {
  /* loop has five parts
   *  1) Check the buttons
   *  2) Check timing events (should we back to resting mode?)
   *  3) Check the frame (did we change from high to low?)
   *  4) Set the light   (is it time to go On or Off?)
   *  5) Set the display
  */
  updateDisplay = 0; //if nothing happend the screen can stay the way it is
  // -- (1) Check the buttons -- //
  //if a button is pressed the screen needs to update
  button=getButton(analogRead(0));
  switch(button) {
    case 0: //right
      if (GUIMode==1){ //view mode -> next setting
        selectedSetting=selectedSetting+1;
        if (selectedSetting==NR_OF_SETTINGS){selectedSetting=0;}
      }
      updateDisplay = 1;
      break;
    case 1: //left
      if (GUIMode==1){ //view mode -> previous setting
        selectedSetting=selectedSetting-1;
        if (selectedSetting==-1){selectedSetting=(NR_OF_SETTINGS-1);}
      }
      updateDisplay = 1;
      break;
    case 2: //up
      if (GUIMode==2){//change mode -> increase new setting
        currentSettings[selectedSetting]++;
        if (selectedSetting==1){//only 0-1-2 for ShutterMode
          if(currentSettings[selectedSetting] == 3){currentSettings[selectedSetting]=0;} 
        }
        //others just not above the overflow (which is -32767)
        if (currentSettings[selectedSetting]<0){currentSettings[selectedSetting]--;}
      }
      updateDisplay = 1;
      break;
    case 3: //down
      if (GUIMode==2){//change mode -> decrease new setting
        currentSettings[selectedSetting]--;
        if (selectedSetting==1){//only 0-1-2 for ShutterMode
          if(currentSettings[selectedSetting] == -1){currentSettings[selectedSetting]=2;}
        }
        //others just not below 0
        if (currentSettings[selectedSetting]<0){currentSettings[selectedSetting]++;}
      }
      updateDisplay = 1;
      break;
    case 4: //selection
      if(GUIMode==0) {//Resting mode -> to view mode
          GUIMode = 1;
          selectedSetting = NR_OF_SETTINGS-1;
          viewStartTime=millis();
      }else if(GUIMode==1){ //View mode -> Reset or go to change mode
          if (selectedSetting==(NR_OF_SETTINGS-1)){ //Reset frame counters
            numberOfFrames=0;
            GUIMode = 0;
          } else {
            GUIMode = 2;
          }
      }else if(GUIMode==2){//Change mode -> Go to View mode
          GUIMode = 1;
          viewStartTime = millis();
      }
      updateDisplay = 1;
      break;
    case 5: //idle
      delayTime=200;
      break;
  }
  
  // -- (2) Check timing events -- //
  if (GUIMode == 1){ //View mode will exit after 5 seconds of inactivity
    if ((millis()-viewStartTime)>5000){
      GUIMode = 0;
      updateDisplay = 2;
    }
    if (updateDisplay){
      viewStartTime=millis();
    }
  }

  // -- (3) Check the frame -- //
  if(currentSettings[1]==2){ //in FrameSync mode
    if(digitalRead(frameInPin)==LOW){ 
      if(framePin){//trigger on falling flank
        numberOfFrames++;
        if(numberOfFrames==currentSettings[4]){reachedFrame=true;}
        if(numberOfFrames==currentSettings[3]){numberOfFrames=0;}
        frameLowTime = millis();
        updateDisplay=2;
      }
      framePin=false;
    }else {
      framePin=true;
    }
  }

  // -- (4) Set the light -- //
  if(lightOn){ //light is on, check if enough time has passed to turn it off
    if((millis()-lightStartTime)>=currentSettings[0]){
        digitalWrite(outPin,LOW);
        lightOn=false;
        lightStopTime=millis();
    }
  } else { //light is off, check either the trigger, or if enough time has passed to turn it back on or enough frames
    if(currentSettings[1]==0){ //triggered
      if(digitalRead(triggerInPin)==LOW&&(!lightOn)&&((millis()-lightStopTime)>500)){
        lightStartTime=millis();
        digitalWrite(outPin,HIGH);
        lightOn=true;
      }
    }else if (currentSettings[1]==1){ //automatic
      if((millis()-lightStopTime)>=((1000*currentSettings[2])-currentSettings[0])){
        lightStartTime=millis();
        digitalWrite(outPin,HIGH);
        lightOn=true;
      }
    }else { //FrameSync
      if ((reachedFrame)&&((millis()-frameLowTime)>currentSettings[5])){
        reachedFrame=false;
        lightStartTime=millis();
        digitalWrite(outPin,HIGH);
        lightOn=true;
      }
    }
  }

  // -- (5) Set the display -- //
  if ((updateDisplay>0)||firstRun){
    firstRun=false;
    lcd.clear();
    switch (GUIMode) {
      case 0: //Resting mode -> display mode
        if(currentSettings[1]==0) {//Triggered
            lcd.print("Triggered Mode");
        }else if(currentSettings[1]==1){//Continuous
            lcd.print("Continuous Mode");
        }else if(currentSettings[1]==2){//FrameSync
            lcd.print("FrameSync");
            lcd.setCursor(0,1);
            lcd.print("Frame "+String(numberOfFrames));
        }
        break;
      case 1: //View Mode
        //inspect settings
        if (selectedSetting==0) { //PulseWidth
            lcd.print("PulseWidth");
            lcd.setCursor(0, 1);lcd.print(String(currentSettings[0])+" ms");
        }else if(selectedSetting==1){ //ShutterMode
            lcd.print("ShutterMode");
            lcd.setCursor(0, 1);
            if (currentSettings[1]==0){lcd.print("Triggered");}
            if (currentSettings[1]==1){lcd.print("Continuous");}
            if (currentSettings[1]==2){lcd.print("FrameSync");}
        }else if(selectedSetting==2){ //PulsePeriod
            lcd.print("PulsePeriod");
            lcd.setCursor(0, 1);lcd.print(String(currentSettings[2])+" s");        
        }else if(selectedSetting==3){ //Total Frames
            lcd.print("Total Frames");
            lcd.setCursor(0, 1);lcd.print(String(currentSettings[3]));         
        }else if(selectedSetting==4){ //Flash Frame
            lcd.print("Flash Frame");
            lcd.setCursor(0, 1);lcd.print(String(currentSettings[4]));    
        }else if(selectedSetting==5){ //Frame Duration
            lcd.print("Frame Duration");
            lcd.setCursor(0, 1);lcd.print(String(currentSettings[5])+" ms");
        }else if(selectedSetting==6){ //Reset
            lcd.print("RESET COUNTER?");
            lcd.setCursor(0, 1);lcd.print("Click SELECT");
        }
        break;
      case 2: //Change Mode
        //inspect settings
        if (selectedSetting==0) { //PulseWidth
            lcd.print("PulseWidth     C");
            lcd.setCursor(0, 1);lcd.print(String(currentSettings[0])+" ms");
        }else if(selectedSetting==1){ //ShutterMode
            lcd.print("ShutterMode    C");
            lcd.setCursor(0, 1);
            if (currentSettings[1]==0){lcd.print("Triggered");}
            if (currentSettings[1]==1){lcd.print("Continuous");}
            if (currentSettings[1]==2){lcd.print("FrameSync");}
        }else if(selectedSetting==2){ //PulsePeriod
            lcd.print("PulsePeriod    C");
            lcd.setCursor(0, 1);lcd.print(String(currentSettings[2])+" s");        
        }else if(selectedSetting==3){ //Total Frames
            lcd.print("Total Frames   C");
            lcd.setCursor(0, 1);lcd.print(String(currentSettings[3]));         
        }else if(selectedSetting==4){ //Flash Frame
            lcd.print("Flash Frame    C");
            lcd.setCursor(0, 1);lcd.print(String(currentSettings[4]));    
        }else if(selectedSetting==5){ //Frame Duration
            lcd.print("Frame Duration C");
            lcd.setCursor(0, 1);lcd.print(String(currentSettings[5])+" ms");
        }else if(selectedSetting==6){ //Reset
            lcd.print("----");
            lcd.setCursor(0, 1);lcd.print("----");
        }
        break;
      case 3: //Store Mode
        lcd.print("SETTING");
        lcd.setCursor(0, 1);
        lcd.print(" SAVED");
        break;
    }
    if(updateDisplay==1){delay(delayTime);}
    if(getButton(analogRead(0))!=5){ //still pressed
      delayTime=10;
    }
  }
}
