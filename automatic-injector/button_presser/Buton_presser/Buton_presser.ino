/****************************************************************************** 
BUTTON_PRESSER V0.1, 14-11-2019
Arduino code for a button presser based on a stepper motor.
Must monitor a button and move the stepper to press a button for a set amount of time

//command to set the delaytime
000100 = 100ms

R.Harkes NKI
(c) 2018 GPLv3

******************************************************************************/

//Declare pin functions on the arduino mega
#define BUTTON1 50
#define BUTTON2 52
#define dir 31
#define stp 33
#define MS3 35
#define MS2 37
#define MS1 39
#define EN 41

#define debug false

//Declare variables for functions
char c;
String userInput;
int steps;
int mode;
boolean error;
int timeInMilliSeconds;

void setup() {  
  pinMode(stp, OUTPUT);
  pinMode(dir, OUTPUT);
  pinMode(MS1, OUTPUT);
  pinMode(MS2, OUTPUT);
  pinMode(MS3, OUTPUT);
  pinMode(EN, OUTPUT);
  pinMode(BUTTON1, INPUT_PULLUP);
  pinMode(BUTTON2, INPUT_PULLUP);

  timeInMilliSeconds = 1000;
  //start low
  digitalWrite(stp, LOW);
  //one direction
  digitalWrite(dir, LOW);
  //enable motor control
  digitalWrite(EN, LOW);
  //speed fastest
  digitalWrite(MS1, LOW);
  digitalWrite(MS2, LOW);
  digitalWrite(MS3, LOW);
  
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
    else //command was given
    { 
      if (userInput.length()==6) 
      { //change in delaytime
        timeInMilliSeconds=userInput.toInt();
        Serial.println(userInput + "_1");
      } 
    } 
    userInput="";
  }//command interpreter
  if (digitalRead(BUTTON1)==LOW)
  {
      turnmotor(timeInMilliSeconds,10);
      delay(500);
  }
  if (digitalRead(BUTTON2)==LOW)
  {
      digitalWrite(EN, HIGH);
  }else {
    digitalWrite(EN,LOW);
  }
}


//Identify the arduino
void Identify()
{
  Serial.println("Button Presser");
  
}

//explaination of the protocol
void Help()
{
  Serial.println("Good Luck");
}


void turnmotor(int timeInMilliSeconds, int steps)
{
  digitalWrite(EN, LOW);
  digitalWrite(dir, LOW);
  for(int x= 1; x<steps; x++)  //Step the motor
  {
    delay(1);
    digitalWrite(stp,HIGH); //Trigger one step forward
    delay(1);
    digitalWrite(stp,LOW); //Pull step pin low so it can be triggered again
  }
  delay(timeInMilliSeconds);
  digitalWrite(dir, HIGH);
  for(int x= 1; x<steps; x++)  //Step the motor
  {
    delay(1);
    digitalWrite(stp,HIGH); //Trigger one step forward
    delay(1);
    digitalWrite(stp,LOW); //Pull step pin low so it can be triggered again
  }
}
