# automation
Home Automation for Air Conditioner

Allows an iOS app to control the settings on an air conditioner.

Includes (1) ESP8266/Arduino code for an IR emitter and temperature sensor and (2) iOS App code (Swift) to generate IR commands for a Friedrich air condtioner.

The ESP8266 has two functions: 
1. The device obtains current temperature and humidity from a DHT sensor every minute and posts the data to the web.
2. The ESP8266 acts as a web server and translates HTTP requests to IR commands that are sent to an air conditioner. The accompanying Swift code used in an iOS app obtains user input for Mode, Temperature and Fan Speed and generates the appropriate IR code, which is then sent to the ESP8266.
