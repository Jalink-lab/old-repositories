/* Simple block of arduino code to set and get registers of any I2C device
 * Be aware: gives complete freedom to mess everything up
 * Adress is a byte (000 - 255)
 * Value is a byte  (000 - 255)
 * 
 * Read Example: 
 * 243
 * > read from 243 value 148
 * Write example:
 * 243148
 * > wrote to 243 value 148
 */
#include <Wire.h>
#define I2C_ADDRESS 0x60

char c;
String userInput;
uint8_t reg;
uint8_t value;

void setup() {
  Serial.begin(9600);
  /* Initialise I2C */
  Wire.begin();
  Serial.println("boot complete");
  Serial.println("Connected to I2C Adress " +String(I2C_ADDRESS));
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
      Serial.println("executing "+userInput);
      if (userInput.length()==6) { //write command
        reg = (uint8_t) userInput.substring(0,3).toInt();
        value = (uint8_t) userInput.substring(3,6).toInt();
        write8(reg, value);
        Serial.println("Wrote to "+String(reg)+" value "+String(value) +" M"+ byte2bitString(value)+"L");
      } else if (userInput.length()==3) { //read command
        reg = (uint8_t) userInput.substring(0,3).toInt();
        value = read8(reg);
        Serial.println("Read from "+String(reg)+" value "+String(value) +" M"+ byte2bitString(value)+"L");
      } else if (userInput.length()==11) { //bitwise command
        reg = (uint8_t) userInput.substring(0,3).toInt();
        value = bitString2Byte(userInput.substring(3,11));
        write8(reg, value);
        Serial.println("Wrote to "+String(reg)+" value "+String(value) +" M"+ byte2bitString(value)+"L");
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
uint8_t bitString2Byte(String s){
  uint8_t value = 0;
  for (int i=7;i>=0;i--){
    if (s.substring(i,i+1)=="1"){
      bitSet(value,7-i);
    }
  }
  return value;
}
String byte2bitString(uint8_t value) {
  String s = "[";
  for (int i=7;i>=0;i--){
    s = s + String(bitRead(value,i));
  }
  s = s+"]";
  return s;
}
// write to registry
void write8 (uint8_t reg, uint8_t value)
{
  Wire.beginTransmission(I2C_ADDRESS);
  Wire.write(reg); //Wire.send(reg);
  Wire.write(value & 0xFF); //Wire.send(value & 0xFF);
  Wire.endTransmission(); 
}
// read from registry
uint8_t read8(uint8_t reg)
{
  Wire.beginTransmission(I2C_ADDRESS);
  Wire.write(reg); //Wire.send(reg);
  Wire.endTransmission();
  Wire.requestFrom(I2C_ADDRESS, 1);
  return Wire.read();
}
