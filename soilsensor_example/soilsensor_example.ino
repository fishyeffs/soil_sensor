#include "Adafruit_seesaw.h"

Adafruit_seesaw ss;

void setup() {
  pinMode(13, OUTPUT);
  Serial.begin(115200);
  while (!Serial) delay(10);

  Serial.println("seesaw Soil Sensor example!");
  
  if (!ss.begin(0x36)) {
    Serial.println("ERROR! seesaw not found");
    while(1) {
      digitalWrite(13, HIGH); delay(50);
      digitalWrite(13, LOW); delay(50);
    }
  } else {
    Serial.print("seesaw started! version: ");
    Serial.println(ss.getVersion(), HEX);
  }
}

void loop() {
  float tempC = ss.getTemp();
  uint16_t capread = ss.touchRead(0);
  Serial.print("Temperature: "); Serial.print(tempC); Serial.println("*C");
  Serial.print("Capacitive: "); Serial.println(capread);
  digitalWrite(13, HIGH); delay(500);
  digitalWrite(13, LOW); delay(500);
}
