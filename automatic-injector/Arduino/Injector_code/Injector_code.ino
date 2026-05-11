/****************************************************************************** 
INJECTOR_CODE V1.1, 10-18-2019
Arduino code for a triple injector. To be operated over a serial connection.
Consists of three stepper motors and three servos.
  To operate servo: Send message of format 'Wyyyy\r' 
  W = [1-3] Motor 
  yyyy = 0000-9999 microseconds (usually will need between 1000 and 2000)

  Example: 12000\r
   result: Move motor to one end

  Arduino will return the command with _1 appended when pulsewidth has been set.
  Or an error when the command cannot be handled.

  ---------------------------------------------------------------------------------
  
  To operate stepper: Send message of format 'WXyyyyZ\r' 
  W = [1-3] Motor 
  X = [0/1] Direction
  yyyyy = 0000-9999 Nr of steps 
  Z = 0-4 Stepsize 
   0 = Full step 
   1 = Half step
   2 = Quarter step
   3 = Eighth step
   4 = Sixteenth step

  Example: 1020002\r
   result: turn motor 1 clockwise for 2000 turns with quarter stepsize

  Arduino will return the command with _1 appended when finished.
  Or an error when the command cannot be handled.
   
R.Harkes NKI
(c) 2018 GPLv3

Based on: SparkFun Easy Driver Basic Demo
Toni Klopfenstein @ SparkFun Electronics
March 2015
https://github.com/sparkfun/Easy_Driver

Simple demo sketch to demonstrate how 5 digital pins can drive a bipolar stepper motor,
using the Easy Driver (https://www.sparkfun.com/products/12779). Also shows the ability to change
microstep size, and direction of motor movement.

Development environment specifics:
Written in Arduino 1.6.0

This code is beerware; if you see me (or any other SparkFun employee) at the local, and you've found our code helpful, please buy us a round!
Distributed as-is; no warranty is given.

Example based off of demos by Brian Schmalz (designer of the Easy Driver).
http://www.schmalzhaus.com/EasyDriver/Examples/EasyDriverExamples.html
******************************************************************************/

//Declare pin functions on the arduino mega
#define srv_1 2
#define srv_2 3
#define srv_3 4

#define dir_1 8
#define stp_1 9
#define MS3_1 10
#define MS2_1 11
#define MS1_1 12
#define EN_1 13

#define dir_2 30
#define stp_2 32
#define MS3_2 34
#define MS2_2 36
#define MS1_2 38
#define EN_2 40

#define dir_3 31
#define stp_3 33
#define MS3_3 35
#define MS2_3 37
#define MS1_3 39
#define EN_3 41
#define debug false

#include <Servo.h>
Servo myservo1;
Servo myservo2;
Servo myservo3;
//Declare variables for functions
char c;
String userInput;
int motor;
int dir;
int steps;
int mode;
boolean error;

void setup() {
  myservo1.attach(srv_1);
  myservo2.attach(srv_2);
  myservo3.attach(srv_3);
  
  pinMode(stp_1, OUTPUT);
  pinMode(dir_1, OUTPUT);
  pinMode(MS1_1, OUTPUT);
  pinMode(MS2_1, OUTPUT);
  pinMode(MS3_1, OUTPUT);
  pinMode(EN_1, OUTPUT);

  pinMode(stp_2, OUTPUT);
  pinMode(dir_2, OUTPUT);
  pinMode(MS1_2, OUTPUT);
  pinMode(MS2_2, OUTPUT);
  pinMode(MS3_2, OUTPUT);
  pinMode(EN_2, OUTPUT);

  pinMode(stp_3, OUTPUT);
  pinMode(dir_3, OUTPUT);
  pinMode(MS1_3, OUTPUT);
  pinMode(MS2_3, OUTPUT);
  pinMode(MS3_3, OUTPUT);
  pinMode(EN_3, OUTPUT);
  
  resetBEDPins(); //Set step, direction, microstep and enable pins to default states
  Serial.begin(9600); //Open Serial connection for control
}

//Main loop
void loop() {
  while(Serial.available()){ //Read user input and store untill line-end
      c = Serial.read(); 
      userInput += c;
  }
  if ((c == '\n')||(c == '\r'))  //command interpreter
  {
    c = ' ';
    userInput.remove(userInput.length()-1,1);
    error = false;
    if (userInput =="*IDN?")
    {
      Identify();
    }
    else if (userInput.equalsIgnoreCase("help"))
    {
      Help();
    }
    else { //command was given
      if (userInput.length()==7) { //stepper command
        motor = userInput.substring(0,1).toInt();
        dir = userInput.substring(1,2).toInt();
        steps = userInput.substring(2,6).toInt();
        mode = userInput.substring(6,7).toInt();
        if (debug) {
          Serial.println("motor: " + String(motor) + "\n");
          Serial.println("dir: " + String(dir) + "\n");
          Serial.println("steps: " + String(steps) + "\n");
          Serial.println("mode: " + String(mode) + "\n");
        }
        error = checkInput(motor,dir,steps,mode);
        if (error) {
          Serial.println("Error wrong stepper input: " + userInput);
        } else {
          digitalWrite(EN_1, LOW); //Pull enable pin low to allow motor control
          digitalWrite(EN_2, LOW); //Pull enable pin low to allow motor control
          digitalWrite(EN_3, LOW); //Pull enable pin low to allow motor control
          turnmotor(motor,dir,steps,mode);
          Serial.println(userInput + "_1");
        }
      } else if (userInput.length()==5) { //servo command
        motor = userInput.substring(0,1).toInt();
        steps = userInput.substring(1,5).toInt();
        if (debug) {
          Serial.println("motor: " + String(motor) + "\n");
          Serial.println("microseconds: " + String(steps) + "\n");
        }
        moveservo(motor,steps);
        Serial.println(userInput + "_1");
      } else {
        Serial.println("Error command not recognised: " + userInput);
      } 
    }
    userInput="";
    resetBEDPins();
  } //command interpreter
}

//Identify the arduino
void Identify()
{
  Serial.println("Triple injector driver");
  
}

//explaination of the protocol
void Help()
{
  Serial.println("Help for the triple injector driver: \n");
  Serial.println(" To operate stepper: Send message of format 'WXyyyyZ\\r' \n");
  Serial.println(" W = [1-3] Motor \n");
  Serial.println(" X = [0/1] Direction \n");
  Serial.println(" yyyy = 0000-9999 Nr of steps \n");
  Serial.println(" Z = 0-3 Stepsize \n");
  Serial.println("  0 = Full step \n");
  Serial.println("  1 = Half step \n");
  Serial.println("  2 = Quarter step \n");
  Serial.println("  3 = Eighth step\n\n");
  Serial.println(" Example: 1020002\\r\n");
  Serial.println(" result: turn motor 1 clockwise for 2000 turns with quarter stepsize\n\n");
  Serial.println(" Arduino will return the command with _1 appended when finished.\n");
  Serial.println(" Or an error when the command cannot be handled.\n\n");
  Serial.println(" To operate servo: Send message of format 'Wyyyy\r' ");
  Serial.println(" W = [1-3] Motor ");
  Serial.println(" yyyy = 0000-9999 microseconds (usually will need between 1000 and 2000)");
  Serial.println(" Example: 12000\r");
  Serial.println(" result: Move motor to one end");
  Serial.println(" Arduino will return the command with _1 appended when pulsewidth has been set.");
  Serial.println(" Or an error when the command cannot be handled.");
}

boolean checkInput(int motor,int dir,int steps,int mode)
{
  error = false;
  if ((motor<1)||(motor>3)){
    error = true;
  }
  if ((dir<0)||(dir>1)){
    error = true;
  }
  if ((steps<0)||(steps>9999)){
    error = true;
  }
  if ((mode<0)||(mode>4)){
    error = true;
  }
  return error;
}
//Reset Big Easy Driver pins to default states
void resetBEDPins()
{
  digitalWrite(stp_1, LOW);
  digitalWrite(dir_1, LOW);
  digitalWrite(MS1_1, LOW);
  digitalWrite(MS2_1, LOW);
  digitalWrite(MS3_1, LOW);
  digitalWrite(EN_1, HIGH);
  
  digitalWrite(stp_2, LOW);
  digitalWrite(dir_2, LOW);
  digitalWrite(MS1_2, LOW);
  digitalWrite(MS2_2, LOW);
  digitalWrite(MS3_2, LOW);
  digitalWrite(EN_2, HIGH);

  digitalWrite(stp_3, LOW);
  digitalWrite(dir_3, LOW);
  digitalWrite(MS1_3, LOW);
  digitalWrite(MS2_3, LOW);
  digitalWrite(MS3_3, LOW);
  digitalWrite(EN_3, HIGH);
}
void moveservo(int motor, int steps)
{
  switch (motor) {
    case 1:
      myservo1.writeMicroseconds(steps);
      break;
    case 2:
      myservo2.writeMicroseconds(steps);
      break;
    case 3:
      myservo3.writeMicroseconds(steps);
      break;     
  }
}
void turnmotor(int motor,int dir,int steps,int mode)
{
  int stp_;
  int dir_;
  int MS1_;
  int MS2_;
  int MS3_;
  int EN_;
  switch (motor) {
    case 1:
      stp_=stp_1;
      dir_=dir_1;
      MS1_=MS1_1;
      MS2_=MS2_1;
      MS3_=MS3_1;
      EN_ =EN_1;
      break;
    case 2:
      stp_=stp_2;
      dir_=dir_2;
      MS1_=MS1_2;
      MS2_=MS2_2;
      MS3_=MS3_2;
      EN_ =EN_2;
      break;
    case 3:
      stp_=stp_3;
      dir_=dir_3;
      MS1_=MS1_3;
      MS2_=MS2_3;
      MS3_=MS3_3;
      EN_ =EN_3;
      break;
  }
  if (dir==0) //set direction
  {
    digitalWrite(dir_, LOW);
  } else
  {
    digitalWrite(dir_, HIGH);
  }
  switch (mode){
    case 0:
      digitalWrite(MS1_, LOW);
      digitalWrite(MS2_, LOW);
      digitalWrite(MS3_, LOW);
      break;
    case 1:
      digitalWrite(MS1_, HIGH);
      digitalWrite(MS2_, LOW);
      digitalWrite(MS3_, LOW);
      break;
    case 2:
      digitalWrite(MS1_, LOW);
      digitalWrite(MS2_, HIGH);
      digitalWrite(MS3_, LOW);
      break;
    case 3:
      digitalWrite(MS1_, HIGH);
      digitalWrite(MS2_, HIGH);
      digitalWrite(MS3_, LOW);
      break;
    case 4:
      digitalWrite(MS1_, HIGH);
      digitalWrite(MS2_, HIGH);
      digitalWrite(MS3_, HIGH);
      break;
  }
  for(int x= 1; x<steps; x++)  //Step the motor
  {
    digitalWrite(stp_,HIGH); //Trigger one step forward
    delay(1);
    digitalWrite(stp_,LOW); //Pull step pin low so it can be triggered again
    delay(1);
  }
}
