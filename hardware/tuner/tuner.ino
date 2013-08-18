#include <SPI.h>
#include <ble.h>

int pinDial1 = A0;
int pinDial2 = A1;
int lastVal1 = -1;
int lastVal2 = -1;
int precision = 25;

int powerIndicatorLedPin = 6;
int connectionIndicatorLedPin = 7;

void setup()
{
  pinMode(powerIndicatorLedPin, OUTPUT);
  pinMode(connectionIndicatorLedPin, OUTPUT);
  
  digitalWrite(powerIndicatorLedPin, HIGH);
  
  SPI.setDataMode(SPI_MODE0);
  SPI.setBitOrder(LSBFIRST);
  SPI.setClockDivider(SPI_CLOCK_DIV16);
  SPI.begin();

  ble_begin();
  
  Serial.begin(9600);
}

void debug_print(char *text) {
  Serial.print(millis());
  Serial.print(" ");
  Serial.println(text);
}

void loop()
{
  if (ble_connected()) {
    digitalWrite(connectionIndicatorLedPin, HIGH);
  } else {
    digitalWrite(connectionIndicatorLedPin, LOW);
  }

  static int lastReportTime = 2000;
  int currentTime = millis();
  int timeDiff = currentTime - lastReportTime;
  if (timeDiff >= 250) {
    lastReportTime = currentTime;
    
    int valDial1 = analogRead(pinDial1);
    int valDial2 = analogRead(pinDial2);
    int diff1 = valDial1 - lastVal1;
    int diff2 = valDial2 - lastVal2;
    if (abs(diff1) > precision || abs(diff2) > precision) {
      ble_write(0x0A);
      ble_write(valDial1 & 0xFF);
      ble_write((valDial1 & 0xFF00) >> 8);
      ble_write(valDial2 & 0xFF);
      ble_write((valDial2 & 0xFF00) >> 8);

      lastVal1 = valDial1;
      lastVal2 = valDial2;
      
      if (precision == 25) {
        precision = 10;
      } else {
        precision = 25;
      }
    } else {
      ble_write(0x0B);
    }
  }
  
  // Allow BLE Shield to send/receive data
  ble_do_events();
}
