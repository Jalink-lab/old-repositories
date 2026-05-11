/* Pulse Regenerator 
 *  Pulse Regenerator for the Toggel Camera based on the Adafruit library
 *  
 *  
 * Copyright (C) 2019 - R.Harkes & K.Jalink NKI
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * 
 */

#include <Wire.h>
#include <Adafruit_SI5351.h>

Adafruit_SI5351 clockgen = Adafruit_SI5351();
char c;
String userInput;

void setup(void) 
{
  Serial.begin(57600);
  //Start connection to clockgen
  if (clockgen.begin() != ERROR_NONE)
  {
    Serial.print("No Si5351 detected");
    while(1);
  }
  //Setting PLL_A to 16x the input signal of 40MHz (640MHz)
  clockgen.setupPLLInt(SI5351_PLL_A, 16); 
  //Setting the Multisynth to output 0 at 1/8th of PLL_A (80MHz)
  clockgen.setupMultisynthInt(0, SI5351_PLL_A, SI5351_MULTISYNTH_DIV_8);
  //Dividing the output by 2 to have the original 40MHz
  clockgen.setupRdiv(0, SI5351_R_DIV_1);

  //Setting PLL_B to 16x the input signal of 40MHz (640MHz)
  clockgen.setupPLLInt(SI5351_PLL_B, 16); 
  //Setting the Multisynth to output 1 at 1/8th of PLL_A (80MHz)
  clockgen.setupMultisynthInt(1, SI5351_PLL_A, SI5351_MULTISYNTH_DIV_8);
  //Dividing the output by 2 to have the original 40MHz
  clockgen.setupRdiv(1, SI5351_R_DIV_1);
  
  //Enable outputs
  clockgen.enableOutputs(true);
  Serial.println("Boot Complete");
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
      Serial.println("Doing OK");
    }
    userInput="";
  } //command interpreter
}

//Identify the arduino
void Identify()
{
  Serial.println("PulseRegenerator");
  
}
