/* Arduino code to control the pulse regenerator via serial commands
 * 
 * At startup it resets the si5351 to the default state for 40 MHz.
 * This is FMD to /16 and OMD x16 to get the same signal back.
 * PLL must be 600-900MHz 40*16 = 640MHz
 * 
 * Command types are specified by the first letter
 * m16 = FMD and OMD multiplier to 16x
 * p90 = faseoffset between 0 and 1 90 degrees
 */
#include <Wire.h>
#define I2C_ADDRESS 0x60

char c;
String userInput;
String comType;
uint8_t reg;
uint8_t value;
uint8_t multiplier;

void setup() {
  Serial.begin(9600);
  /* Initialise I2C */
  Wire.begin();
  resetSi5351();
  multiplier=16;
  setSi5351(multiplier);
  enableOutputs();
  Serial.println("boot complete");
  Serial.println("Connected to I2C Adress " +String(I2C_ADDRESS));
  Serial.println("Set multiplier to " +String(multiplier)+"x");
}
void resetSi5351(){
  write8(3,255); //disable all outputs
  write8(16,128); //clk0 off
  write8(17,128); //clk1 off
  write8(183,19); //10pF load
  write8(165,0); //phase offset clk0 to 0
  write8(166,0); //phase offset clk0 to 0
}
void setSi5351(uint8_t multiplier){ 
  //Only integers p1 = 128 * div - 512 ; p2 = 0; p3 = 1;
  //No end stage dividers
  //at the momement it sets only 16

  //set Feedback Multisynth Divider (FMD) for PLL_A
  write8(26,0);
  write8(27,1);
  write8(28,0); 
  write8(29,6);
  write8(30,0);
  write8(31,0);
  write8(32,0);
  write8(33,0);

  //set Output Multisynth Divider (OMD) for output 0
  write8(42,0);
  write8(43,1);
  write8(44,0);
  write8(45,6);
  write8(46,0);
  write8(47,0);
  write8(48,0);
  write8(49,0);
  write8(50,0);
}
void demo(){ //shifts phase of clk1 forward and back
  for (int i = 0;i<17;i++){
    write8(166,i*4); //first two bits dont do anything
    write8(177,32);  //reset PLLA
    delay(200);
  }
  for (int i = 16;i>=0;i--){
    write8(166,i*4); //first two bits dont do anything
    write8(177,32);  //reset PLLA
    delay(200);
  }
}
void enableOutputs(){
  write8(16,79); //couple both to PLL_A
  write8(17,79);
  write8(177,32);//reset PLL_A
  write8(3,0); //enable outputs
}
void loop() {
  while(Serial.available()){ //Read user input and store untill line-end
      c = Serial.read(); 
      userInput += c;
  }
  if ((c == '\n')||(c == '\r'))  //command interpreter
  {
    c = ' ';
    userInput.remove(userInput.length()-1,1);
    if (userInput =="*IDN?")
    {
      Identify();
    }
    else {
      comType = userInput.substring(0,1);
      
      if (comType=="m") { //multiplier
        
      } else if (comType=="p") { //phase
        //set the phaseoffset of clk1. [0..31]
        write8(166,userInput.substring(1,4).toInt()*4); //first two bits dont do anything
        write8(177,32);//reset PLLA
        Serial.println("Set PhaseOffset clk1 to " + String(userInput.substring(1,4).toInt()));
      } else if (comType=="d") {//demo
        demo();
      } else {
        Serial.println("Error command not recognised: " + userInput);
      } 
    }
    userInput="";
  } //command interpreter
}

//Identify the arduino
void Identify()
{
  Serial.println("i2c tester");
  
}
// write to registry
void write8(uint8_t reg, uint8_t value)
{
  Wire.beginTransmission(I2C_ADDRESS);
  Wire.write(reg); //Wire.send(reg);
  Wire.write(value & 0xFF); //Wire.send(value & 0xFF);
  Wire.endTransmission(); 
}
