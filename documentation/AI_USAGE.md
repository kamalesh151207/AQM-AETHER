# AI Usage Documentation
## AQM AETHER – Smart Air Quality Monitoring System

---

## 1. Project Information

**Project Name:** AQM AETHER – Smart Air Quality Monitoring System  
**Microcontroller:** ESP32 DevKit  
**Programming Language:** C/C++  
**Mobile Application:** Flutter and Dart  
**Communication Protocol:** Bluetooth Low Energy (BLE)

This document describes the use of Artificial Intelligence tools during the planning, development, debugging, documentation, and presentation of the AQM AETHER project.

---

## 2. AI Tools Used

The following AI tools were used as development assistants:

| AI Tool | Purpose |
|---|---|
| ChatGPT | Firmware guidance, code explanations, debugging assistance, BLE configuration, and documentation |
| Google Gemini | Technical explanations, development assistance, and documentation support |
| Antigravity | Development workflow and project organization assistance |

Only tools actually used during the project should be listed.

---

## 3. Areas Where AI Assistance Was Used

### 3.1 Hardware Configuration

AI assistance was used to understand the connections and functions of the hardware components.

Components discussed:

- ESP32 DevKit
- DHT22 temperature and humidity sensor
- MQ-2 gas sensor
- MPU6050 accelerometer and gyroscope

AI assistance helped with understanding:
- GPIO pin configuration.
- I2C communication.
- Sensor initialization.
- Analog sensor readings.
- Hardware integration concepts.

### 3.2 Embedded Firmware Development

AI assistance was used to develop and understand the ESP32 firmware written in C/C++.

The firmware development involved:

- Sensor initialization.
- Temperature and humidity acquisition.
- MQ-2 analog data acquisition.
- MPU6050 motion data acquisition.
- Sensor data processing.
- Sampling interval configuration.
- Serial Monitor output.
- BLE communication.

AI-generated code was treated as a development reference and required review and testing before use.

### 3.3 Bluetooth Low Energy Integration

AI assistance was used to understand BLE implementation on ESP32.

The assistance covered:

- BLE device initialization.
- BLE server creation.
- Service and characteristic configuration.
- UUID organization.
- Read and Write properties.
- Notification-based sensor data transmission.
- Connection and disconnection callbacks.

The BLE device name used in the project is:

`AQM-Kamalesh`

### 3.4 Mobile Application Development

AI assistance supported the understanding and development of the Flutter-based mobile application.

Areas included:

- BLE device discovery.
- Device connection workflow.
- Sensor data presentation.
- Application interface structure.
- Communication between the ESP32 and mobile application.

### 3.5 Documentation and Repository Organization

AI assistance was also used to organize the GitHub repository and prepare technical documentation.

This included:

- README.md preparation.
- Hardware configuration documentation.
- Library dependency documentation.
- AI usage documentation.
- Testing methodology.
- Known limitations.
- Repository folder organization.

---

## 4. Example Prompts Used

The following are representative examples of prompts used during development.

### Prompt 1 – ESP32 Firmware

"Help me develop ESP32 firmware for an air quality monitoring system using DHT22, MQ-2, and MPU6050 sensors. Include sensor initialization, data acquisition, serial output, and Bluetooth Low Energy communication."

### Prompt 2 – BLE Integration

"Explain how to configure an ESP32 BLE server with a custom service UUID and multiple characteristics for transmitting sensor readings to a Flutter mobile application."

### Prompt 3 – Sensor Integration

"Explain how to connect and read data from DHT22, MQ-2, and MPU6050 sensors using an ESP32 DevKit. Include GPIO configuration and I2C communication."

### Prompt 4 – Debugging

"Help identify and resolve errors in ESP32 firmware involving sensor initialization, BLE communication, and sensor data transmission."

### Prompt 5 – Documentation

"Prepare technical documentation for an ESP32-based air quality monitoring system, including hardware configuration, software architecture, BLE characteristics, testing methodology, and limitations."

---

## 5. Human Modifications and Development Decisions

AI assistance was used as a supporting resource rather than as a replacement for development and engineering decisions.

The project development process involved:

- Reviewing generated code before integration.
- Adjusting GPIO assignments according to the hardware configuration.
- Organizing sensor-specific functionality.
- Defining the BLE service and characteristic UUID structure.
- Reviewing sensor output through the Serial Monitor.
- Modifying firmware based on compilation errors and observed behavior.
- Organizing documentation according to the project requirements.

Final implementation details must be checked against the actual source code and hardware configuration.

---

## 6. Testing and Verification

AI-generated suggestions and code require independent verification.

The following verification activities are relevant to the project:

| Test Area | Verification Method |
|---|---|
| ESP32 initialization | Serial Monitor |
| DHT22 readings | Temperature and humidity output |
| MQ-2 readings | Analog sensor output |
| MPU6050 readings | Accelerometer and gyroscope output |
| BLE advertising | nRF Connect device scanner |
| BLE connection | Actual connection through a BLE client |
| BLE notifications | Received characteristic updates |
| Mobile application | Testing on an Android device |

Only tests actually performed should be marked as completed in the final submission.

---

## 7. Limitations and Responsible AI Usage

AI-generated code and explanations may contain errors, incomplete implementations, or assumptions about hardware and library versions.

Therefore:

- AI-generated code should not be considered automatically correct.
- Hardware connections must be checked against component specifications.
- Sensor readings must be validated independently.
- BLE communication must be tested on the actual hardware.
- Calibration is necessary before reporting quantitative gas concentrations.
- Project claims must reflect the actual implemented and tested functionality.

The MQ-2 sensor provides analog gas/smoke response readings in this implementation. It does not independently provide calibrated ppm measurements.

The current sensor configuration does not directly measure PM1.0, PM2.5, PM10, or CO₂.

---

## 8. Contribution of AI to the Project

AI tools supported the development process by helping with:

- Understanding hardware components.
- Exploring embedded programming concepts.
- Developing and reviewing firmware.
- Understanding BLE communication.
- Structuring the mobile application.
- Debugging and interpreting errors.
- Preparing technical documentation.

The project-specific hardware configuration, implementation decisions, integration, testing, and final verification remain the responsibility of the project developer.

---

## 9. Declaration

AI tools were used as supporting development resources during the creation of AQM AETHER.

Their outputs were used for learning, technical guidance, code assistance, debugging, and documentation. AI-generated material was not treated as independently verified evidence of successful hardware or software operation.

The final submission should accurately represent the code, components, features, and tests implemented by the developer.

---

**Project:** AQM AETHER – Smart Air Quality Monitoring System  
**Repository:** https://github.com/kamalesh151207/AQM-AETHER