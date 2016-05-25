#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <ESP8266WebServer.h>
#include <ESP8266mDNS.h>

#include "DHT.h"
#define DHTTYPE DHT11
#define DHTPIN  D1 //GPIO 5

#include <IRremoteESP8266.h>
IRsend irsend(D5);

int led1Pin = D0; //GPIO 16
int led2Pin = D4; //GPIO 2

const char* mDNSName = "LR_AC";
const char* ssid     = "ssid";
const char* password = "password";

ESP8266WebServer server(80);
 
// Initialize DHT sensor 
DHT dht(DHTPIN, DHTTYPE);

void gettemperature();
void handle_root();
void handle_code();
void send_ac(String);

float humidity, temp;
String webString="";

unsigned long previousMillis = 0;
unsigned long interval = 3000;
unsigned long retryInterval = 3000;

void setup(void)
{
  Serial.begin(115200);
  dht.begin();
  irsend.begin();
  
  // Connect to WiFi network
  WiFi.begin(ssid, password);
  Serial.print("Working to connect");

  // Wait for connection
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\r\n");
  Serial.println("DHT Temp/Hum Server");
  Serial.println("Connected to " + String(ssid));
   
  server.on("/", handle_root);
  server.on("/code",handle_code);
  
  server.begin();
  Serial.print("HTTP server: ");
  Serial.println(WiFi.localIP());
    
  if (!MDNS.begin(mDNSName)) {
    Serial.println("Error setting up MDNS responder!");
    while(1) { 
      delay(1000);
    }
  }

  Serial.println("mDNS responder: " + String(mDNSName) + ".local");
  
}
 
void loop(void)
{
  gettemperature();
  server.handleClient(); 
}

void gettemperature() {
  unsigned long currentMillis = millis();
 
  if((unsigned long)(currentMillis - previousMillis) >= interval) {
    previousMillis = currentMillis;   

    // Reading temperature for humidity takes about 250 milliseconds!
    // Sensor readings may also be up to 2 seconds 'old' (it's a very slow sensor)
 
    // Check if any reads failed and exit early (to try again)
    if (isnan(dht.readHumidity()) || isnan(dht.readTemperature())) {
      Serial.println("Failed to read from DHT sensor!");

      previousMillis = previousMillis - interval + retryInterval;
      
      return;
    }
    else {
      interval = 60000; // Update interval to 60000
      
      humidity = dht.readHumidity();          // Read humidity (percent)
      temp = dht.readTemperature();     // Read temperature as Celsius

      WiFiClient client;
      const char *host = "192.168.3.166";
      const int httpPort = 80;
      if (!client.connect(host, httpPort)) {
        Serial.println("HTTP connection failed");
        return;
      }
      
      // We now create a URI for the request
      String url = "/esp8266/temp.php?temp=" + String(temp) + "&hum=" + String(humidity) + "&table=" + String(mDNSName);
      Serial.print("Requesting URL: ");
      Serial.println(url);
      
      // This will send the request to the server
      client.print(String("GET ") + url + " HTTP/1.1\r\n" +
                   "Host: " + host + "\r\n" + 
                   "Connection: close\r\n\r\n");
      delay(500);
      
    }
  }
}

void handle_root() {
  webString = "{";
  webString += "\"humidity\":" + String(humidity);
  webString += ",";
  webString += "\"temp\":" + String(temp);
  webString += ",";
  webString += "\"led1\":" + String(digitalRead(led1Pin));
  webString += ",";
  webString += "\"led2\":" + String(digitalRead(led2Pin));
  webString += ",";
  webString += "\"currentMillis\":" + String(millis());
  webString += ",";
  webString += "\"previousMillis\":" + String(previousMillis);
  webString += ",";
  webString += "\"interval\":" + String(interval);
  webString += "}";
  
  server.send(200, "application/json", webString);
  delay(100);
}

void handle_code() {

  if(server.args() != 1) {
    server.send(200, "text/plain", "Page Not Found");
    delay(100);
    return;
  }

  if(server.argName(0) == "led1") {
    pinMode(led1Pin, OUTPUT);

    if(server.arg(0) == "on") {
      digitalWrite(led1Pin, LOW);
    }
    else if (server.arg(0) == "off") {
      digitalWrite(led1Pin, HIGH);
    }
  }

  else if(server.argName(0) == "led2") {
    pinMode(led2Pin, OUTPUT);

    if(server.arg(0) == "on") {
      digitalWrite(led2Pin, LOW);
    }
    else if (server.arg(0) == "off") {
      digitalWrite(led2Pin, HIGH);
    }
  }

  else if(server.argName(0) == "ac") {
    send_ac(server.arg(0));
  }
  
  webString = server.argName(0) + ":" + server.arg(0);
  
  server.send(200, "text/html", webString);
  delay(100);
   
}

void send_ac(String selector) {
  
  String inputString = "0x" + selector;
  const char *cstring = inputString.c_str();
  unsigned int code = strtoul(cstring, NULL, 16);

  irsend.sendLG(code, 28);
  
  delay(100);
  
  Serial.println(code, HEX);
  
}
