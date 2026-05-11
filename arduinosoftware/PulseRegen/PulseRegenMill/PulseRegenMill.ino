#include "si5351.h"
#include "Wire.h"

Si5351 si5351;
char c;
String userInput;

void setup()
{
  // Start serial and initialize the Si5351
  Serial.begin(57600);
  bool i2c_found;
  //initialize the si5351. it believes it has 25MHz input
  i2c_found = si5351.init(SI5351_CRYSTAL_LOAD_8PF, 0, 0);
  if(!i2c_found)
  {
    Serial.println("Device not found on I2C bus!");
  }

  // Since the hardware expects 25. we will multiply with 16 for 400MHz
  si5351.set_pll(40000000000ULL,SI5351_PLLA);
  si5351.output_enable(SI5351_CLK0,1);
  // Couple CLK0 to PLLA
  si5351.set_ms_source(SI5351_CLK0, SI5351_PLLA);
  // Set MultiSynth
  struct Si5351RegSet ms_reg;
  ms_reg.p1 = 512; //divide 8 so 128*8-512
  ms_reg.p2 = 0;
  ms_reg.p3 = 1;
  si5351.set_ms(SI5351_CLK0, ms_reg, 1, 1, 0); //integer mode, no rdivide 2, and no extra divide 4
  si5351.pll_reset(SI5351_PLLA);
  si5351.update_status();
 
  delay(500);
  Serial.println("Boot complete.");
}

void loop() //simple serial reader that responds with status if needed
{
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
      si5351.update_status();
      Serial.print("SYS_INIT: ");
      Serial.print(si5351.dev_status.SYS_INIT);
      Serial.print("  LOL_A: ");
      Serial.print(si5351.dev_status.LOL_A);
      Serial.print("  LOL_B: ");
      Serial.print(si5351.dev_status.LOL_B);
      Serial.print("  LOS: ");
      Serial.print(si5351.dev_status.LOS);
      Serial.print("  REVID: ");
      Serial.println(si5351.dev_status.REVID);
    }
    userInput="";
  } //command interpreter
}

//Identify the arduino
void Identify()
{
  Serial.println("PulseRegenerator");
  
}
