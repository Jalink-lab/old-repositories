#define checkPin 11
boolean pinHigh;

void setup() {
  Serial.begin(9600); //Open Serial connection for control
  pinMode(checkPin, INPUT_PULLUP);
  pinHigh = true;
}


void loop() {
  if (digitalRead(checkPin)!=pinHigh){
    pinHigh=digitalRead(checkPin);
    Serial.print("Poort " + String(checkPin)+":");
    Serial.println(digitalRead(checkPin));
  }
  delay(10);
}
