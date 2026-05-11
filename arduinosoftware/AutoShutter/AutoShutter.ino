/* Auto Shutter for the Leica Lamp
 * The button has been connected to the outside via two bananaplugs
 * This program aims to allow the user to set the following properties
 * - Pulse width
 * - Period
 * - Triggerd / Continuous
 * 
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
#define inPin 2  //Digital pin 2
#define outPin 3 //Digital pin 3
boolean event;
boolean firstrun;
boolean lightOn; //is the light on?
unsigned long lightStartTime;
unsigned long lightStopTime;
byte button;
char emptyString[16] = "                ";
int currentSettings[3];
int currentSelection;
int delayTime;
int steps[4]={1,10,100,1000};
int currentStep;
// initialize the library with the numbers of the interface pins
LiquidCrystal lcd(8, 9, 4, 5, 6, 7);

void setup() {
  pinMode(inPin,INPUT_PULLUP);
  pinMode(outPin,OUTPUT);
  currentSelection=0;
  currentSettings[0] = 1000; //ms pulsewidth
  currentSettings[1] = 2; //s period
  currentSettings[2] = 1;    //triggered
  currentStep = 1;
  lightStopTime=millis();
  lightOn=false;
  delayTime=200;
  firstrun=true;
  // set up the LCD's number of columns and rows: 
  lcd.begin(16, 2);
  // Print a message to the LCD.
  lcd.print("Welcome");
}

void loop() {
  button=getButton(analogRead(0));
  event = true;
  switch(button) {
    case 0: //right
      currentSelection=currentSelection+1;
      if(debug){
        lcd.setCursor(0, 0);lcd.print(emptyString);
        lcd.setCursor(0, 0);lcd.print("RightButton:");
        lcd.setCursor(0, 1);lcd.print(emptyString);
        lcd.setCursor(0, 1);lcd.print(String(currentSelection));
        delay(1000);
      }
      break;
    case 1: //up
      if(currentSelection==2){
        currentSettings[currentSelection]=currentSettings[currentSelection]+1;
        if (currentSettings[2]==2){currentSettings[2]=0;}
        if (currentSettings[2]==1){lightStopTime=millis();}//startTriggeredMode
      } else {
        currentSettings[currentSelection]=currentSettings[currentSelection]+steps[currentStep];
        if(currentSettings[currentSelection]<0){currentSettings[currentSelection]=32767;}
      }
      break;
    case 2: //down
      if(currentSelection==2){
        currentSettings[currentSelection]=currentSettings[currentSelection]-1;
        if (currentSettings[2]==-1){currentSettings[2]=1;}
        if (currentSettings[2]==1){lightStopTime=millis();}//startTriggeredMode
      } else {
        currentSettings[currentSelection]=currentSettings[currentSelection]-steps[currentStep];
        if(currentSettings[currentSelection]<0){currentSettings[currentSelection]=0;}
      }
      break;
    case 3: //left
      currentSelection=currentSelection-1;
      if(debug){
        lcd.setCursor(0, 0);lcd.print(emptyString);
        lcd.setCursor(0, 0);lcd.print("LeftButton:");
        lcd.setCursor(0, 1);lcd.print(emptyString);
        lcd.setCursor(0, 1);lcd.print(String(currentSelection));
        delay(1000);
      }
      break;
    case 4: //selection
      currentStep++;
      if(currentStep>3){currentStep=0;}
      lcd.setCursor(0, 0);lcd.print(emptyString);
      lcd.setCursor(0, 0);lcd.print("Step Size:");
      lcd.setCursor(0, 1);lcd.print(emptyString);
      lcd.setCursor(0, 1);lcd.print(String(steps[currentStep]));
      delay(1000);
      break;
    case 5: //idle
      event = false;
      break;
  }
  if(firstrun){firstrun=false;event=true;}
  if (event){
    if (currentSettings[2]==-1){currentSettings[2]=1;}
    if (currentSelection==3){currentSelection=0;}
    if (currentSelection==-1){currentSelection=2;}
    if(debug){
      lcd.setCursor(0, 0);lcd.print(emptyString);
      lcd.setCursor(0, 0);lcd.print("Selection:");
      lcd.setCursor(0, 1);lcd.print(emptyString);
      lcd.setCursor(0, 1);lcd.print(String(currentSelection));
      delay(1000);
    }
    if(debug){Serial.println("current selection = "+currentSelection);}
    switch(currentSelection){
      case 0:
        lcd.setCursor(0, 0);lcd.print(emptyString);
        lcd.setCursor(0, 0);lcd.print("Pulse width: ");
        lcd.setCursor(0, 1);lcd.print(emptyString);
        lcd.setCursor(0, 1);lcd.print(String(currentSettings[0])+" ms");
        break;
      case 1:
        lcd.setCursor(0, 0);lcd.print(emptyString);
        lcd.setCursor(0, 0);lcd.print("Period: ");
        lcd.setCursor(0, 1);lcd.print(emptyString);
        lcd.setCursor(0, 1);lcd.print(String(currentSettings[1])+" s");
        break;
      case 2:
        lcd.setCursor(0, 0);lcd.print(emptyString);
        lcd.setCursor(0, 0);lcd.print("triggered: ");
        lcd.setCursor(0, 1);lcd.print(emptyString);
        if (currentSettings[2]==1){
          lcd.setCursor(0, 1);lcd.print("true");
        }else{
          lcd.setCursor(0, 1);lcd.print("false");
        }
        break;
    }
    delay(delayTime);
    if(getButton(analogRead(0))!=5){ //still pressed
      delayTime=10;
    }
  }else{ //no event so let's see how the pulse is doing
    delayTime=200;
    if(lightOn){ //light is on, check if enough time has passed to turn it off
      if((millis()-lightStartTime)>=currentSettings[0]){
          digitalWrite(outPin,LOW);
          lightOn=false;
          emptyString[15]=32;
          lightStopTime=millis();
      }
    } else { //light is off, check either the trigger, or if enough time has passed to turn it back on
      if(currentSettings[2]){ //triggered
        if(digitalRead(inPin)==LOW&&(!lightOn)&&((millis()-lightStopTime)>500)){
          lightStartTime=millis();
          digitalWrite(outPin,HIGH);
          lightOn=true;
          emptyString[15]=219;
        }
      }else{ //automatic
        if((millis()-lightStopTime)>=((1000*currentSettings[1])-currentSettings[0])){
          lightStartTime=millis();
          digitalWrite(outPin,HIGH);
          lightOn=true;
          emptyString[15]=219;
        }
      }
    }
  }
}

byte getButton(int input){
  if (input<50){
    return 0;
  }else if (input<177){
    return 1;
  }else if (input<333){
    return 2;
  }else if (input<525){
    return 3;
  }else if (input<832){
    return 4;
  }else{
    return 5;
  }
}
