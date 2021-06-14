#include <ArduinoBLE.h>

// This device's MAC:
// C8:5C:A2:2B:61:86
//#define LEDR        (23u)
//#define LEDG        (22u)
//#define LEDB        (24u)

// Device name
const char* nameOfPeripheral = "Vianna's";
const char* uuidOfService = "00001101-0000-1000-8000-00805f9b34fb";
const char* uuidOfRxChar = "00001142-0000-1000-8000-00805f9b34fb";
const char* uuidOfTxChar = "00001143-0000-1000-8000-00805f9b34fb";

// BLE Service
BLEService HTSService(uuidOfService);

// RX / TX Characteristics
BLEByteCharacteristic txChar(uuidOfTxChar, BLERead | BLENotify | BLEBroadcast);

const int FLEX_PIN_0 = A6; // Pin connected to voltage divider output
const int FLEX_PIN_1 = A3; // Pin connected to voltage divider output
const int FLEX_PIN_2 = A2; // Pin connected to voltage divider output
const int FLEX_PIN_3 = A1; // Pin connected to voltage divider output
const int FLEX_PIN_4 = A0; // Pin connected to voltage divider output

// Measure the voltage at 5V and the actual resistance of your
// 47k resistor, and enter them below:
const float VCC = 7.2; // Measured voltage of Ardunio 3.3V line
const float R_DIV = 10000.0; // Measured resistance of 10k resistor

// Upload the code, then try to adjust these values to more
// accurately calculate bend degree.
float STRAIGHT_RESISTANCE_0 = 0; // resistance when straight
float BEND_RESISTANCE_0 = 0; // resistance at 90 deg
float STRAIGHT_RESISTANCE_1 = 0; // resistance when straight
float BEND_RESISTANCE_1 = 0; // resistance at 90 deg
float STRAIGHT_RESISTANCE_2 = 0; // resistance when straight
float BEND_RESISTANCE_2 = 0; // resistance at 90 deg
float STRAIGHT_RESISTANCE_3 = 0; // resistance when straight
float BEND_RESISTANCE_3 = 0; // resistance at 90 deg
float STRAIGHT_RESISTANCE_4 = 0; // resistance when straight
float BEND_RESISTANCE_4 = 0; // resistance at 90 deg

/*
 *  MAIN
 */
void setup() {

  // Start serial.
  Serial.begin(9600);

  // Ensure serial port is ready.
  while (!Serial);

  // Prepare LED pins.
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(LEDR, OUTPUT);
  pinMode(LEDG, OUTPUT);

  startFlex();
  // Start BLE.
  startBLE();

  // Create BLE service and characteristics.
  BLE.setLocalName(nameOfPeripheral);
  BLE.setAdvertisedService(HTSService);
  HTSService.addCharacteristic(txChar);
  BLE.addService(HTSService);

  // Bluetooth LE connection handlers.
  BLE.setEventHandler(BLEConnected, onBLEConnected);
  BLE.setEventHandler(BLEDisconnected, onBLEDisconnected);
  
  // Let's tell devices about us.
  BLE.advertise();
  
  // Print out full UUID and MAC address.
  Serial.println("Peripheral advertising info: ");
  Serial.print("Name: ");
  Serial.println(nameOfPeripheral);
  Serial.print("MAC: ");
  Serial.println(BLE.address());
  Serial.print("Service UUID: ");
  Serial.println(HTSService.uuid());
  Serial.print("rxCharacteristic UUID: ");
  Serial.println(uuidOfRxChar);
  Serial.print("txCharacteristics UUID: ");
  Serial.println(uuidOfTxChar);
  

  Serial.println("Bluetooth device active, waiting for connections...");
}


void loop()
{
  BLEDevice central = BLE.central();
  
  if (central)
  {
    // Only send data if we are connected to a central device.
    while (central.connected()) {
      connectedLight();
      getFlexReading();
      delay(50);   
    }
  } else {
    disconnectedLight();
  }
}


/*
 *  BLUETOOTH
 */
void startBLE() {
  if (!BLE.begin())
  {
    Serial.println("starting BLE failed!");
    while (1);
  }
}

void onBLEConnected(BLEDevice central) {
  Serial.print("Connected event, central: ");
  Serial.println(central.address());
  connectedLight();
}

void onBLEDisconnected(BLEDevice central) {
  Serial.print("Disconnected event, central: ");
  Serial.println(central.address());
  disconnectedLight();
}


/*
 *  flex sensor initialization 
 */
void startFlex() {
  Serial.println("Keep hand still at 0 degrees for 5 seconds");
  delay(5000);
  STRAIGHT_RESISTANCE_0 = getResistance(FLEX_PIN_0);
  delay(100);
  Serial.println("Bend finger at 90 degrees for 5 seconds");
  delay(5000);
  BEND_RESISTANCE_0 = getResistance(FLEX_PIN_0);
  delay(100);
  
  Serial.println("Keep hand still at 0 degrees for 5 seconds");
  delay(5000);
  STRAIGHT_RESISTANCE_1 = getResistance(FLEX_PIN_1);
  STRAIGHT_RESISTANCE_3 = getResistance(FLEX_PIN_3);
  STRAIGHT_RESISTANCE_2 = getResistance(FLEX_PIN_2);
  STRAIGHT_RESISTANCE_4 = getResistance(FLEX_PIN_4);
  delay(100);
  Serial.println("Bend finger at 90 degrees for 5 seconds");
  delay(5000);
  BEND_RESISTANCE_1 = getResistance(FLEX_PIN_1);
  BEND_RESISTANCE_3 = getResistance(FLEX_PIN_3);
  BEND_RESISTANCE_2 = getResistance(FLEX_PIN_2);
  BEND_RESISTANCE_4 = getResistance(FLEX_PIN_4);
  delay(100);
}


// get flex sensor reading
float getResistance(int FLEX_PIN) {
  int flexADC = analogRead(FLEX_PIN);
  float flexV = flexADC * VCC / 1023.0;
  float flexR = R_DIV * (VCC / flexV - 1.0);
  return flexR;
}

void getFlexReading() {
  // Read the ADC, and calculate voltage and resistance from it
  int resistance_0 = getResistance(FLEX_PIN_0);
  int resistance_1 = getResistance(FLEX_PIN_1);
  int resistance_2 = getResistance(FLEX_PIN_2);
  int resistance_3 = getResistance(FLEX_PIN_3);
  int resistance_4 = getResistance(FLEX_PIN_4);

//   Use the calculated resistance to estimate the sensor's
//   bend angle:
  int angle_0 = map(resistance_0, STRAIGHT_RESISTANCE_0, BEND_RESISTANCE_0, 0, 90.0);
  if (angle_0 < 0){
    angle_0 = 0; 
  }
  int angle_1 = map(resistance_1, STRAIGHT_RESISTANCE_1, BEND_RESISTANCE_1, 0, 90.0);
  if (angle_1 < 0){
    angle_1 = 0; 
  }
  int angle_2 = map(resistance_2, STRAIGHT_RESISTANCE_2, BEND_RESISTANCE_2, 0, 90.0);
  if (angle_2 < 0){
    angle_2 = 0; 
  }
  int angle_3 = map(resistance_3, STRAIGHT_RESISTANCE_3, BEND_RESISTANCE_3, 0, 90.0);
  if (angle_3 < 0){
    angle_3 = 0; 
  }
  int angle_4 = map(resistance_4, STRAIGHT_RESISTANCE_4, BEND_RESISTANCE_4, 0, 90.0);
  if (angle_4 < 0){
    angle_4 = 0; 
  }

  txChar.writeValue(angle_0);
  txChar.writeValue(angle_1);
  txChar.writeValue(angle_2);
  txChar.writeValue(angle_3);
  txChar.writeValue(angle_4);
}


/*
 * LEDS
 */
void connectedLight() {
  digitalWrite(LEDR, LOW);
  digitalWrite(LEDG, HIGH);
}


void disconnectedLight() {
  digitalWrite(LEDR, HIGH);
  digitalWrite(LEDG, LOW);
}
