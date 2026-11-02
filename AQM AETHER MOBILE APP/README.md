# AQM AETHER
## Environmental Intelligence & Sensor Monitoring Platform

> *"Understand Your Environment."*

---

## Overview

AQM AETHER is a professional Flutter application for real-time environmental monitoring via BLE (Bluetooth Low Energy) connection to an ESP32-based IoT device (AQM-Kamalesh).

**Platform:** Android (Flutter)  
**Design System:** Arctic Graphite  
**Architecture:** Provider + SQLite  
**Target:** Android 5.0+ (API 21+)

---

## Prerequisites — INSTALL THESE FIRST

### 1. Flutter SDK (Required)

Flutter is **not optional** — the app cannot be built or run without it.

```bash
# Create development directory
mkdir -p ~/development
cd ~/development

# Download Flutter (macOS Apple Silicon)
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.27.4-stable.zip

# Download Flutter (macOS Intel)
# curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.27.4-stable.zip

# Extract
unzip flutter_macos_arm64_3.27.4-stable.zip

# Add to PATH — add to ~/.zshrc:
echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify
flutter --version
```

### 2. Android Studio + SDK

```bash
# Install Android SDK tools
flutter doctor --android-licenses
```

Accept all licenses when prompted.

### 3. Java Development Kit (JDK 17)

```bash
# macOS with Homebrew
brew install openjdk@17
```

---

## Project Setup

```bash
cd "AQM AETHER"

# Install Flutter dependencies
flutter pub get

# Verify project health
flutter analyze

# Run on connected Android device
flutter run

# Build debug APK
flutter build apk --debug

# APK location after build:
# build/app/outputs/flutter-apk/app-debug.apk
```

---

## Install APK on Android Device

```bash
# Option 1: ADB (USB debugging enabled on device)
adb install build/app/outputs/flutter-apk/app-debug.apk

# Option 2: Transfer the APK file directly to the phone and open it
# Enable "Install from unknown sources" in Android Settings → Security
```

---

## ESP32 BLE Device: AQM-Kamalesh

### BLE Configuration

| Parameter | Value |
|---|---|
| Device Name | `AQM-Kamalesh` |
| Service UUID | `12345678-1234-1234-1234-123456789001` |
| Temperature UUID | `12345678-1234-1234-1234-123456789002` |
| Humidity UUID | `12345678-1234-1234-1234-123456789003` |
| Sampling Interval UUID | `12345678-1234-1234-1234-123456789004` |
| Alert UUID | `12345678-1234-1234-1234-123456789005` |

### Data Format

The ESP32 firmware transmits sensor values as **UTF-8 encoded strings**:
- Temperature: `"25.3"` (°C, 1 decimal place)
- Humidity: `"64.7"` (%, 1 decimal place)
- Sampling interval: `"5"` (integer seconds)

The app also attempts binary (little-endian int) parsing as fallback.

---

## Application Structure

```
lib/
├── main.dart                          # Entry point
├── core/
│   ├── theme/app_theme.dart           # Arctic Graphite design system
│   ├── constants/ble_constants.dart   # BLE UUIDs, device name
│   └── utils/app_utils.dart           # Formatting, BLE payload parsing
├── models/
│   ├── sensor_reading.dart            # Sensor data model
│   ├── device_model.dart              # BLE device state model
│   └── monitoring_event.dart          # Event log model
├── services/
│   ├── ble_service.dart               # BLE scanning, connection, GATT
│   ├── storage_service.dart           # SQLite persistence
│   └── csv_export_service.dart        # CSV export + share
├── providers/
│   ├── device_provider.dart           # BLE state management
│   ├── monitoring_provider.dart       # Readings & events
│   ├── analytics_provider.dart        # Statistics & trends
│   └── settings_provider.dart         # App preferences
└── screens/
    ├── main_shell.dart                # Navigation shell
    ├── command_center/                # Main dashboard
    ├── live_monitor/                  # Real-time charts
    ├── intelligence/                  # Analytics & export
    ├── device_lab/                    # BLE configuration
    └── settings/                      # App settings
```

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_blue_plus` | ^1.35.3 | BLE communication |
| `provider` | ^6.1.2 | State management |
| `sqflite` | ^2.3.3+1 | Local SQLite database |
| `shared_preferences` | ^2.3.2 | App preferences |
| `fl_chart` | ^0.69.0 | Professional charts |
| `csv` | ^6.0.0 | CSV generation |
| `path_provider` | ^2.1.4 | File system paths |
| `share_plus` | ^10.0.3 | Share CSV files |
| `permission_handler` | ^11.3.1 | Android BLE permissions |
| `intl` | ^0.19.0 | Date/time formatting |
| `collection` | ^1.18.0 | Collection utilities |
| `rxdart` | ^0.28.0 | Reactive streams |

---

## Android Permissions

The app requests:
- `BLUETOOTH_SCAN` — scan for BLE devices
- `BLUETOOTH_CONNECT` — connect to ESP32
- `ACCESS_FINE_LOCATION` — required for BLE scan on Android < 12

No unnecessary permissions are requested.

---

## Known Limitations

1. **Simulated sensor data**: The ESP32 prototype uses simulated temperature and humidity. Readings do NOT represent real environmental conditions.

2. **Not a certified air quality monitor**: No PM2.5, PM10, CO2, or VOC sensors are present in the current prototype.

3. **BLE tested against firmware spec only**: Hardware testing requires physical ESP32 device with AQM-Kamalesh firmware flashed.

4. **iOS not supported**: BLE permissions and configuration are Android-only.

5. **Moving average**: The firmware implements a 5-sample moving average. The app displays the averaged output, not raw sensor values.

---

## Architecture Notes

### BLE Communication
- `BleService` handles all BLE state: scan → connect → discover → subscribe → notify
- Callbacks propagate data to `DeviceProvider` via simple function pointers
- Reconnection: up to 3 automatic attempts with 3-second delay
- Stale data detection: readings older than 2 minutes are flagged

### Data Persistence
- SQLite via `sqflite` stores up to 5,000 sensor readings
- Events log capped at 500 entries
- Data survives app restarts

### State Management
- Provider pattern throughout
- `DeviceProvider` owns BLE state
- `MonitoringProvider` owns historical data
- `AnalyticsProvider` computes stats reactively

---

## Design System: Arctic Graphite

| Token | Color | Hex |
|---|---|---|
| Background Primary | Dark Navy | `#0A1018` |
| Background Secondary | | `#101A26` |
| Panel Background | | `#142232` |
| Elevated Surface | | `#1B2C3E` |
| Accent Primary | Teal | `#54E0C1` |
| Accent Secondary | Blue | `#61A9FF` |
| Temperature | Amber | `#FFB86B` |
| Humidity | Sky Blue | `#79BFFF` |
| Success | Green | `#55D6A4` |
| Warning | Yellow | `#F6C76B` |
| Critical | Red | `#FF7185` |

Typography: **Manrope** (Google Fonts — embedded in assets)

---

*AQM AETHER — Prototype v1.0.0*  
*Environmental data for demonstration purposes only.*

