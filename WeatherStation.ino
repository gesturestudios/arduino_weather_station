#include <Ethernet.h>
#include <MySQL_Connection.h>
#include <MySQL_Cursor.h>
#include <SimpleDHT.h>
#include <Wire.h>
#include <Adafruit_BMP085.h>

// setup for mysql library
byte mac_addr[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
IPAddress server_addr(192, 168, 1, 1);  // IP of the MySQL *server* here
char user[] = "username";              // MySQL user login username
char password[] = "password";        // MySQL user login password
String statement = "";
EthernetClient client;
MySQL_Connection conn((Client *)&client);

// setup for DHT11
int pinDHT11 = A3;
SimpleDHT11 dht11;
byte temperature = 0;
byte humidity = 0;

// setup BMP085 pressure sensor
Adafruit_BMP085 bmp;

// setup timers:
unsigned long currentT = 0; // the timer
unsigned long duration = 5; // duration between insert attempts (minutes)
unsigned long dur = duration*60*1000; // variable to be set short in case of reset
unsigned long last_insert = (millis()-dur); // set to initiate immediate insert

void setup() {
  Serial.begin(115200);
  while (!Serial); // wait for serial port to connect
  Ethernet.begin(mac_addr);
  if (!bmp.begin()) { //Serial.println("Could not find a valid BMP085 sensor, check wiring!");
  }
}

void loop() {
  currentT = millis(); 
  if (currentT - last_insert > dur) {
    get_temps();
    insert_statement();
  }

}


void insert_statement() {
  //Serial.println ("Assembling the insert query...");
  statement="INSERT INTO test_arduino.temps (temp_c,humid,pressure,temp_date) VALUES (";
  statement+=String(bmp.readTemperature());
  statement+=(",");
  statement+=String(humidity);
  statement+=(",");
  statement+=String(bmp.readPressure());
  statement+=",CURRENT_TIMESTAMP)";
  char INSERT_SQL[statement.length()+1];
  statement.toCharArray(INSERT_SQL,statement.length()+1);
  //Serial.println(INSERT_SQL);
  Serial.println("Connecting...");
  if (conn.connect(server_addr, 3306, user, password)) {
    //Serial.println("connected!");
    delay(1000);
    
    //Serial.print("Initiating query...");
    MySQL_Cursor *cur_mem = new MySQL_Cursor(&conn);
    //Serial.println("initiated! Now inserting statement...");
    cur_mem->execute(INSERT_SQL);
    conn.close();                  // close the connection
    //Serial.print("Insert successful, repeating in ");
    //Serial.print(duration);
    //Serial.println(" minutes");
    delete cur_mem;
    dur = duration*60*1000;
    last_insert = millis();

  } else {
    Serial.println("Connect failed. Trying again in 30 seconds...");
    dur = 30000;
    last_insert = millis();
  }
  
}

void get_temps() {
  //Serial.println("Recording data.");
  if (dht11.read(pinDHT11, &temperature, &humidity, NULL)) {
    //Serial.print("Read DHT11 failed.");
    return;
  }
  //Serial.print((int)temperature); Serial.print(" *C, "); 
  //Serial.print((int)humidity); Serial.println(" %");
}

