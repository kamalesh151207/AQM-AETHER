// AQM AETHER — Sensor Reading Model with Gas & Motion Telemetry

class SensorReading {
  final int? id;
  final DateTime timestamp;
  final double? temperature;
  final double? humidity;
  final bool isTemperatureSimulated;
  final bool isHumiditySimulated;

  // MQ-135 Gas Sensor Telemetry (Raw 12-bit ADC 0–4095)
  final int? gasRawAdc;

  // MPU6050 6-Axis Motion Telemetry
  final double? accelX; // g
  final double? accelY; // g
  final double? accelZ; // g
  final double? gyroX;  // °/s
  final double? gyroY;  // °/s
  final double? gyroZ;  // °/s

  const SensorReading({
    this.id,
    required this.timestamp,
    this.temperature,
    this.humidity,
    this.isTemperatureSimulated = true,
    this.isHumiditySimulated = true,
    this.gasRawAdc,
    this.accelX,
    this.accelY,
    this.accelZ,
    this.gyroX,
    this.gyroY,
    this.gyroZ,
  });

  SensorReading copyWith({
    int? id,
    DateTime? timestamp,
    double? temperature,
    double? humidity,
    bool? isTemperatureSimulated,
    bool? isHumiditySimulated,
    int? gasRawAdc,
    double? accelX,
    double? accelY,
    double? accelZ,
    double? gyroX,
    double? gyroY,
    double? gyroZ,
  }) {
    return SensorReading(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      isTemperatureSimulated: isTemperatureSimulated ?? this.isTemperatureSimulated,
      isHumiditySimulated: isHumiditySimulated ?? this.isHumiditySimulated,
      gasRawAdc: gasRawAdc ?? this.gasRawAdc,
      accelX: accelX ?? this.accelX,
      accelY: accelY ?? this.accelY,
      accelZ: accelZ ?? this.accelZ,
      gyroX: gyroX ?? this.gyroX,
      gyroY: gyroY ?? this.gyroY,
      gyroZ: gyroZ ?? this.gyroZ,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'temperature': temperature,
      'humidity': humidity,
      'is_temp_simulated': isTemperatureSimulated ? 1 : 0,
      'is_humidity_simulated': isHumiditySimulated ? 1 : 0,
      'gas_raw_adc': gasRawAdc,
      'accel_x': accelX,
      'accel_y': accelY,
      'accel_z': accelZ,
      'gyro_x': gyroX,
      'gyro_y': gyroY,
      'gyro_z': gyroZ,
    };
  }

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      id: map['id'] as int?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      temperature: (map['temperature'] as num?)?.toDouble(),
      humidity: (map['humidity'] as num?)?.toDouble(),
      isTemperatureSimulated: (map['is_temp_simulated'] as int? ?? 1) == 1,
      isHumiditySimulated: (map['is_humidity_simulated'] as int? ?? 1) == 1,
      gasRawAdc: (map['gas_raw_adc'] as num?)?.toInt(),
      accelX: (map['accel_x'] as num?)?.toDouble(),
      accelY: (map['accel_y'] as num?)?.toDouble(),
      accelZ: (map['accel_z'] as num?)?.toDouble(),
      gyroX: (map['gyro_x'] as num?)?.toDouble(),
      gyroY: (map['gyro_y'] as num?)?.toDouble(),
      gyroZ: (map['gyro_z'] as num?)?.toDouble(),
    );
  }

  String toCsvRow() {
    final ts = timestamp.toIso8601String();
    final temp = temperature?.toStringAsFixed(2) ?? '';
    final hum = humidity?.toStringAsFixed(2) ?? '';
    final gas = gasRawAdc?.toString() ?? '';
    final ax = accelX?.toStringAsFixed(3) ?? '';
    final ay = accelY?.toStringAsFixed(3) ?? '';
    final az = accelZ?.toStringAsFixed(3) ?? '';
    final gx = gyroX?.toStringAsFixed(2) ?? '';
    final gy = gyroY?.toStringAsFixed(2) ?? '';
    final gz = gyroZ?.toStringAsFixed(2) ?? '';
    return '$ts,$temp,$hum,$gas,$ax,$ay,$az,$gx,$gy,$gz';
  }

  static String csvHeader() {
    return 'Timestamp,Temperature (°C),Humidity (%),MQ-135 RAW ADC,Accel X (g),Accel Y (g),Accel Z (g),Gyro X (°/s),Gyro Y (°/s),Gyro Z (°/s)';
  }
}

