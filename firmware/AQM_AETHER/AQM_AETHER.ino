/*
==========================================================
       AQM AETHER - SMART AIR QUALITY MONITORING SYSTEM
==========================================================

Board         : ESP32 DevKit
Sensors       : DHT11 + MQ-2
Communication : Bluetooth Low Energy
Language      : C/C++ (Arduino Framework)

BLE Device    : AQM-Kamalesh

DHT11 DATA    : GPIO 4
MQ-2 AO       : GPIO 34 (through voltage divider)

FEATURES:
- Temperature monitoring
- Humidity monitoring
- MQ-2 raw ADC monitoring
- BLE notifications
- Adjustable sampling interval
- Alert generation
- BLE advertising restart after disconnection

==========================================================
*/

#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <DHT.h>

// ========================================================
// 1. CONFIGURATION
// ========================================================

#define DEVICE_NAME "AQM-Kamalesh"

#define DHT_PIN 4
#define DHT_TYPE DHT11

#define MQ2_PIN 34

#define DEFAULT_INTERVAL 2
#define MIN_INTERVAL 2
#define MAX_INTERVAL 3600

#define TEMP_ALERT_LIMIT 30.0
#define HUMIDITY_ALERT_LIMIT 60.0

// Example raw ADC threshold, not a calibrated ppm value.
#define GAS_RAW_ALERT_LIMIT 2000

#define BLE_RESTART_DELAY 500

// ========================================================
// 2. BLE UUIDS
// ========================================================

#define SERVICE_UUID \
"12345678-1234-1234-1234-123456789001"

#define TEMPERATURE_UUID \
"12345678-1234-1234-1234-123456789002"

#define HUMIDITY_UUID \
"12345678-1234-1234-1234-123456789003"

#define INTERVAL_UUID \
"12345678-1234-1234-1234-123456789004"

#define ALERT_UUID \
"12345678-1234-1234-1234-123456789005"

#define GAS_UUID \
"12345678-1234-1234-1234-123456789006"

// ========================================================
// 3. OBJECTS
// ========================================================

DHT dht(DHT_PIN, DHT_TYPE);

BLEServer* pServer = nullptr;
BLEAdvertising* pAdvertising = nullptr;

BLECharacteristic* pTemperatureCharacteristic = nullptr;
BLECharacteristic* pHumidityCharacteristic = nullptr;
BLECharacteristic* pIntervalCharacteristic = nullptr;
BLECharacteristic* pAlertCharacteristic = nullptr;
BLECharacteristic* pGasCharacteristic = nullptr;

// ========================================================
// 4. GLOBAL VARIABLES
// ========================================================

volatile bool deviceConnected = false;
volatile bool restartAdvertisingRequested = false;

volatile unsigned long disconnectTime = 0;

bool sensorError = false;

unsigned long samplingInterval =
    DEFAULT_INTERVAL * 1000UL;

unsigned long previousSampleTime = 0;

float temperature = 0.0;
float humidity = 0.0;

int gasRawValue = 0;

// Function declarations

void initializeBLE();
void initializeSensors();

void handleBLEAdvertising();
void handleSerialCommands();

void updateIntervalCharacteristic();
void updateBLEData();

void readSensors();
void printSensorData();

String generateAlert();

// ========================================================
// 5. BLE SERVER CALLBACKS
// ========================================================

class AQMServerCallbacks : public BLEServerCallbacks {

    void onConnect(BLEServer* server) override {

        deviceConnected = true;

        restartAdvertisingRequested = false;

        Serial.println();
        Serial.println("================================");
        Serial.println("       BLE CLIENT CONNECTED");
        Serial.println("================================");
    }

    void onDisconnect(BLEServer* server) override {

        deviceConnected = false;

        disconnectTime = millis();

        restartAdvertisingRequested = true;

        Serial.println();
        Serial.println("================================");
        Serial.println("       BLE CLIENT DISCONNECTED");
        Serial.println("       ADVERTISING REQUESTED");
        Serial.println("================================");
    }
};

// ========================================================
// 6. INTERVAL CALLBACK
// ========================================================

class IntervalCallbacks : public BLECharacteristicCallbacks {

    void onWrite(
        BLECharacteristic* characteristic
    ) override {

        String input = characteristic->getValue();

        input.trim();

        if (input.length() == 0) {

            Serial.println("Empty interval received");

            return;
        }

        // Validate numeric input

        for (int i = 0; i < input.length(); i++) {

            if (!isDigit(input[i])) {

                Serial.println("Invalid interval");

                return;
            }
        }

        long seconds = input.toInt();

        if (
            seconds < MIN_INTERVAL ||
            seconds > MAX_INTERVAL
        ) {

            Serial.println("Interval out of range");

            return;
        }

        samplingInterval =
            (unsigned long)seconds * 1000UL;

        updateIntervalCharacteristic();

        Serial.print("Sampling interval updated: ");

        Serial.print(seconds);

        Serial.println(" seconds");
    }
};

// ========================================================
// 7. BLE INITIALIZATION
// ========================================================

void initializeBLE() {

    Serial.println();
    Serial.println("Initializing BLE...");

    // Initialize BLE device

    BLEDevice::init(DEVICE_NAME);

    // Create BLE server

    pServer = BLEDevice::createServer();

    pServer->setCallbacks(
        new AQMServerCallbacks()
    );

    // Create service

    BLEService* pService =
        pServer->createService(SERVICE_UUID);

    // --------------------------------
    // TEMPERATURE CHARACTERISTIC
    // --------------------------------

    pTemperatureCharacteristic =
        pService->createCharacteristic(
            TEMPERATURE_UUID,
            BLECharacteristic::PROPERTY_READ |
            BLECharacteristic::PROPERTY_NOTIFY
        );

    pTemperatureCharacteristic->addDescriptor(
        new BLE2902()
    );

    // --------------------------------
    // HUMIDITY CHARACTERISTIC
    // --------------------------------

    pHumidityCharacteristic =
        pService->createCharacteristic(
            HUMIDITY_UUID,
            BLECharacteristic::PROPERTY_READ |
            BLECharacteristic::PROPERTY_NOTIFY
        );

    pHumidityCharacteristic->addDescriptor(
        new BLE2902()
    );

    // --------------------------------
    // INTERVAL CHARACTERISTIC
    // --------------------------------

    pIntervalCharacteristic =
        pService->createCharacteristic(
            INTERVAL_UUID,
            BLECharacteristic::PROPERTY_READ |
            BLECharacteristic::PROPERTY_WRITE
        );

    pIntervalCharacteristic->setCallbacks(
        new IntervalCallbacks()
    );

    // --------------------------------
    // ALERT CHARACTERISTIC
    // --------------------------------

    pAlertCharacteristic =
        pService->createCharacteristic(
            ALERT_UUID,
            BLECharacteristic::PROPERTY_READ |
            BLECharacteristic::PROPERTY_NOTIFY
        );

    pAlertCharacteristic->addDescriptor(
        new BLE2902()
    );

    // --------------------------------
    // GAS CHARACTERISTIC
    // --------------------------------

    pGasCharacteristic =
        pService->createCharacteristic(
            GAS_UUID,
            BLECharacteristic::PROPERTY_READ |
            BLECharacteristic::PROPERTY_NOTIFY
        );

    pGasCharacteristic->addDescriptor(
        new BLE2902()
    );

    // --------------------------------
    // INITIAL VALUES
    // --------------------------------

    pTemperatureCharacteristic->setValue("0.0");

    pHumidityCharacteristic->setValue("0.0");

    pIntervalCharacteristic->setValue("2");

    pAlertCharacteristic->setValue("NORMAL");

    pGasCharacteristic->setValue("0");

    // --------------------------------
    // START SERVICE
    // --------------------------------

    pService->start();

    // --------------------------------
    // ADVERTISING CONFIGURATION
    // --------------------------------

    pAdvertising = BLEDevice::getAdvertising();

    BLEAdvertisementData advertisementData;

    BLEAdvertisementData scanResponseData;

    // Primary advertising packet

    advertisementData.setFlags(0x06);

    advertisementData.setCompleteServices(
        BLEUUID(SERVICE_UUID)
    );

    // Scan response packet

    scanResponseData.setName(DEVICE_NAME);

    // Apply advertising data

    pAdvertising->setAdvertisementData(
        advertisementData
    );

    pAdvertising->setScanResponseData(
        scanResponseData
    );

    pAdvertising->setScanResponse(true);

    // Start advertising

    pAdvertising->start();

    Serial.println();
    Serial.println("================================");
    Serial.println("          BLE STATUS");
    Serial.println("================================");

    Serial.print("Device Name: ");

    Serial.println(DEVICE_NAME);

    Serial.print("Service UUID: ");

    Serial.println(SERVICE_UUID);

    Serial.println("BLE INITIALIZED");

    Serial.println("Advertising started");

    Serial.println("================================");
}

// ========================================================
// 8. BLE ADVERTISING RESTART
// ========================================================

void handleBLEAdvertising() {

    if (
        restartAdvertisingRequested &&
        !deviceConnected
    ) {

        // Allow time for disconnection cleanup

        if (
            millis() - disconnectTime <
            BLE_RESTART_DELAY
        ) {

            return;
        }

        restartAdvertisingRequested = false;

        Serial.println();

        Serial.println(
            "Restarting BLE advertising..."
        );

        if (pServer != nullptr) {

            BLEDevice::startAdvertising();

            Serial.println(
                "BLE advertising restarted"
            );

        } else {

            Serial.println(
                "BLE server unavailable"
            );
        }
    }
}

// ========================================================
// 9. UPDATE INTERVAL CHARACTERISTIC
// ========================================================

void updateIntervalCharacteristic() {

    if (pIntervalCharacteristic == nullptr) {

        return;
    }

    unsigned long seconds =
        samplingInterval / 1000UL;

    String value = String(seconds);

    pIntervalCharacteristic->setValue(
        value.c_str()
    );
}

// ========================================================
// 10. SENSOR INITIALIZATION
// ========================================================

void initializeSensors() {

    Serial.println();
    Serial.println("Initializing sensors...");

    dht.begin();

    pinMode(MQ2_PIN, INPUT);

    analogReadResolution(12);

    Serial.println("DHT11 initialized");

    Serial.println("MQ-2 initialized");

    Serial.println(
        "MQ-2 warm-up required"
    );
}

// ========================================================
// 11. SENSOR READING
// ========================================================

void readSensors() {

    float newTemperature =
        dht.readTemperature();

    float newHumidity =
        dht.readHumidity();

    int newGasValue =
        analogRead(MQ2_PIN);

    if (
        isnan(newTemperature) ||
        isnan(newHumidity)
    ) {

        sensorError = true;

        Serial.println(
            "DHT11 SENSOR ERROR"
        );

        return;
    }

    sensorError = false;

    temperature = newTemperature;

    humidity = newHumidity;

    gasRawValue = newGasValue;
}

// ========================================================
// 12. ALERT GENERATION
// ========================================================

String generateAlert() {

    String alert = "";

    if (temperature > TEMP_ALERT_LIMIT) {

        alert += "TEMP_HIGH;";
    }

    if (humidity > HUMIDITY_ALERT_LIMIT) {

        alert += "HUMIDITY_HIGH;";
    }

    if (gasRawValue > GAS_RAW_ALERT_LIMIT) {

        alert += "GAS_RAW_HIGH;";
    }

    if (alert.length() == 0) {

        return "NORMAL";
    }

    return alert;
}

// ========================================================
// 13. BLE DATA UPDATE
// ========================================================

void updateBLEData() {

    if (
        pTemperatureCharacteristic == nullptr ||
        pHumidityCharacteristic == nullptr ||
        pGasCharacteristic == nullptr ||
        pAlertCharacteristic == nullptr
    ) {

        return;
    }

    String tempValue =
        String(temperature, 1);

    String humidityValue =
        String(humidity, 1);

    String gasValue =
        String(gasRawValue);

    String alertValue =
        generateAlert();

    // Update characteristic values

    pTemperatureCharacteristic->setValue(
        tempValue.c_str()
    );

    pHumidityCharacteristic->setValue(
        humidityValue.c_str()
    );

    pGasCharacteristic->setValue(
        gasValue.c_str()
    );

    pAlertCharacteristic->setValue(
        alertValue.c_str()
    );

    // Send notifications

    if (deviceConnected) {

        pTemperatureCharacteristic->notify();

        pHumidityCharacteristic->notify();

        pGasCharacteristic->notify();

        pAlertCharacteristic->notify();
    }
}

// ========================================================
// 14. SERIAL MONITOR OUTPUT
// ========================================================

void printSensorData() {

    Serial.println();

    Serial.println("================================");

    Serial.println("       AQM AETHER MONITOR");

    Serial.println("================================");

    if (sensorError) {

        Serial.println("DHT11: SENSOR ERROR");

    } else {

        Serial.print("Temperature: ");

        Serial.print(temperature);

        Serial.println(" C");

        Serial.print("Humidity: ");

        Serial.print(humidity);

        Serial.println(" %");
    }

    Serial.print("MQ-2 Raw ADC: ");

    Serial.println(gasRawValue);

    Serial.print("Alert: ");

    Serial.println(generateAlert());

    Serial.print("BLE: ");

    Serial.println(
        deviceConnected ? "CONNECTED" : "DISCONNECTED"
    );

    Serial.print("Interval: ");

    Serial.print(samplingInterval / 1000UL);

    Serial.println(" seconds");

    Serial.println("================================");
}

// ========================================================
// 15. SERIAL COMMAND HANDLING
// ========================================================

void handleSerialCommands() {

    if (!Serial.available()) {

        return;
    }

    String command =
        Serial.readStringUntil('\n');

    command.trim();

    command.toUpperCase();

    if (command == "GET TEMP") {

        Serial.println(temperature);
    }

    else if (command == "GET HUM") {

        Serial.println(humidity);
    }

    else if (command == "GET GAS") {

        Serial.println(gasRawValue);
    }

    else if (command == "STATUS") {

        printSensorData();
    }

    else if (command == "HELP") {

        Serial.println();
        Serial.println("AVAILABLE COMMANDS:");

        Serial.println("GET TEMP");

        Serial.println("GET HUM");

        Serial.println("GET GAS");

        Serial.println("STATUS");

        Serial.println("HELP");

        Serial.println("SET INTERVAL <seconds>");
    }

    else if (
        command.startsWith("SET INTERVAL ")
    ) {

        String value =
            command.substring(13);

        value.trim();

        bool valid = value.length() > 0;

        for (int i = 0; i < value.length(); i++) {

            if (!isDigit(value[i])) {

                valid = false;

                break;
            }
        }

        if (valid) {

            long seconds = value.toInt();

            if (
                seconds >= MIN_INTERVAL &&
                seconds <= MAX_INTERVAL
            ) {

                samplingInterval =
                    (unsigned long)seconds * 1000UL;

                updateIntervalCharacteristic();

                Serial.println(
                    "Sampling interval updated"
                );

            } else {

                Serial.println(
                    "Interval must be between 2 and 3600 seconds"
                );
            }

        } else {

            Serial.println("Invalid interval");
        }
    }

    else {

        Serial.println(
            "Unknown command. Type HELP."
        );
    }
}

// ========================================================
// 16. SETUP
// ========================================================

void setup() {

    Serial.begin(115200);

    delay(1000);

    Serial.println();

    Serial.println("================================");

    Serial.println("       AQM AETHER SYSTEM");

    Serial.println("================================");

    initializeSensors();

    initializeBLE();

    previousSampleTime = millis();

    Serial.println();

    Serial.println("SYSTEM READY");

    Serial.println("Type HELP for commands.");
}

// ========================================================
// 17. MAIN LOOP
// ========================================================

void loop() {

    // Handle BLE advertising restart

    handleBLEAdvertising();

    // Handle serial commands

    handleSerialCommands();

    unsigned long currentTime = millis();

    // Sensor sampling

    if (
        currentTime - previousSampleTime >=
        samplingInterval
    ) {

        previousSampleTime = currentTime;

        readSensors();

        if (!sensorError) {

            updateBLEData();

            printSensorData();

        } else {

            if (pAlertCharacteristic != nullptr) {

                pAlertCharacteristic->setValue(
                    "DHT_SENSOR_ERROR"
                );

                if (deviceConnected) {

                    pAlertCharacteristic->notify();
                }
            }
        }
    }

    delay(10);
}