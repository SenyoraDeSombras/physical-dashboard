
/**
 * @file dashboard.ino
 * @author Alicia aka SenyoraDeSombras
 * @brief Parses commands via Serial and updates PWM duty cycle and 7segment dispaly.
 * 
 * Hardware: ESP32
 * Platform: Arduino
 */

#include <Arduino.h>
#include <TM1637Display.h>

// --- Configuration ---
// Using constexpr for type-safety and efficiency
constexpr uint8_t PWM_PIN = D14;          // GPIO pin to drive the output
constexpr uint32_t BAUD_RATE = 9600;  // Standard high-speed baud
constexpr char PREFIX_NDL[] = "Set NDL: ";  // The command prefix for needle
constexpr char PREFIX_HIB[] = "Set HIB: ";  // The command prefix for high byte on 7seg indicator
constexpr char PREFIX_LOB[] = "Set LOB: ";  // The command prefix for low byte on 7seg indicator
constexpr char PREFIX_REQ[] = "Who A U?";  // The command prefix device detect
constexpr size_t PREFIX_LEN = sizeof(PREFIX_NDL) - 1;
//Display set up
#define CLK D8
#define DIO D9

TM1637Display display(CLK, DIO);

// --- Global State ---
uint8_t currentNDLValue = 0;
uint8_t currentHIBValue = 88;
uint8_t currentLOBValue = 88;
/**
 * @brief Handles the parsing and logic of the incoming serial string.
 * @param input The raw string received from Serial
 */
void processSerialCommand(String input) {
    // 1. Remove potential carriage returns/newlines from the end
    input.trim();
    if (input.startsWith(PREFIX_REQ)) {
		while (!Serial && millis() < 2000);
        Serial.println(F("DASHBRD"));
    }
    // 2. Check if the string starts with the required prefix
    if (input.startsWith(PREFIX_NDL) || input.startsWith(PREFIX_HIB) || input.startsWith(PREFIX_LOB)) {
        
        // 3. Extract the substring following the prefix
        String valueStr = input.substring(PREFIX_LEN);
        
        // 4. Convert to integer
        int parsedValue = valueStr.toInt();

        // 5. Validation (Safety first in embedded!)
        // Ensure the value is within the valid 8-bit PWM range [0, 255]
        // For needle
        if (input.startsWith(PREFIX_NDL) && parsedValue >= 0 && parsedValue <= 225) {
            currentNDLValue = static_cast<uint8_t>(parsedValue);
            
            // Apply the PWM signal
            analogWrite(PWM_PIN, currentNDLValue);

      
        } 
        // For high byte on 7seg indicator
        if (input.startsWith(PREFIX_HIB) && parsedValue >= 0 && parsedValue <= 99) {
            currentHIBValue = static_cast<uint8_t>(parsedValue);
            
            // Apply the PWM signal
            display.showNumberDec(currentHIBValue, true, 2, 0);  

           
        } 
        // For low byte on 7seg indicator
        if (input.startsWith(PREFIX_LOB) && parsedValue >= 0 && parsedValue <= 99) {
            currentLOBValue = static_cast<uint8_t>(parsedValue);
            
            // Apply the PWM signal
            display.showNumberDec(currentLOBValue, true, 2, 2);  

        } 
    } 
}

void setup() {
    // Initialize Hardware
    pinMode(PWM_PIN, OUTPUT);
    analogWrite(PWM_PIN, 0); // Start with 0 duty cycle

    // Initialize Communication
    Serial.begin(BAUD_RATE);
    
    // Wait for Serial to stabilize (important for native USB ESP32-S3/C3)
    while (!Serial && millis() < 2000);

    display.setBrightness(0x0f);
    uint8_t data[] = { 0xff, 0xff, 0xff, 0xff };
    display.setSegments(data);
}

void loop() {
    // Non-blocking check for serial data
    if (Serial.available() > 0) {
        // Read until newline character
        String incomingBuffer = Serial.readStringUntil('\n');
        
        // Delegate logic to the processor
        processSerialCommand(incomingBuffer);
    }

}
