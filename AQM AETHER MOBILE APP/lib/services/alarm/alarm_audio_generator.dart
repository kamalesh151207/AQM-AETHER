// AQM AETHER — Audio Alarm Tone Synthesizer
// Generates clean in-memory PCM WAV audio bytes for industrial warning chimes

import 'dart:math';
import 'dart:typed_data';

class AlarmAudioGenerator {
  /// Generates a pulsating dual-frequency warning chime (e.g. 880Hz + 1174Hz)
  /// formatted as a valid 16-bit PCM Mono WAV file.
  static Uint8List generateWarningWav({
    double durationSeconds = 1.2,
    int sampleRate = 44100,
  }) {
    final int numSamples = (sampleRate * durationSeconds).round();
    final int dataSize = numSamples * 2; // 16-bit = 2 bytes per sample
    final int fileSize = 44 + dataSize;

    final ByteData byteData = ByteData(fileSize);

    // 1. RIFF Header
    _writeString(byteData, 0, 'RIFF');
    byteData.setUint32(4, fileSize - 8, Endian.little);
    _writeString(byteData, 8, 'WAVE');

    // 2. fmt Sub-chunk
    _writeString(byteData, 12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    byteData.setUint16(20, 1, Endian.little);  // AudioFormat (1 = PCM)
    byteData.setUint16(22, 1, Endian.little);  // NumChannels (1 = Mono)
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    byteData.setUint16(32, 2, Endian.little);  // BlockAlign
    byteData.setUint16(34, 16, Endian.little); // BitsPerSample (16 bits)

    // 3. data Sub-chunk
    _writeString(byteData, 36, 'data');
    byteData.setUint32(40, dataSize, Endian.little);

    // 4. Sample Generation: Dual-beep alert pattern
    // Beep 1 (0.0s to 0.4s): 880 Hz
    // Silence (0.4s to 0.55s)
    // Beep 2 (0.55s to 0.95s): 1046.5 Hz (High C)
    // Decay tail (0.95s to 1.2s)
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      double sample = 0.0;

      if (t < 0.4) {
        // First chime burst (880Hz) with smooth attack & decay
        final double env = _envelope(t, 0.0, 0.4, attack: 0.02, decay: 0.15);
        sample = sin(2 * pi * 880.0 * t) * 0.7 * env;
        sample += sin(2 * pi * 1760.0 * t) * 0.2 * env; // Add octave harmonic
      } else if (t >= 0.55 && t < 0.95) {
        // Second chime burst (1046.5Hz)
        final double localT = t - 0.55;
        final double env = _envelope(localT, 0.0, 0.4, attack: 0.02, decay: 0.15);
        sample = sin(2 * pi * 1046.5 * t) * 0.8 * env;
        sample += sin(2 * pi * 2093.0 * t) * 0.2 * env;
      }

      // Clamp to 16-bit signed integer [-32768, 32767]
      final int intSample = (sample.clamp(-1.0, 1.0) * 32767).toInt();
      byteData.setInt16(44 + i * 2, intSample, Endian.little);
    }

    return byteData.buffer.asUint8List();
  }

  static double _envelope(
    double t,
    double start,
    double end, {
    double attack = 0.02,
    double decay = 0.2,
  }) {
    if (t < start || t > end) return 0.0;
    final double elapsed = t - start;
    final double duration = end - start;

    if (elapsed < attack) {
      return elapsed / attack;
    }
    final double remaining = duration - elapsed;
    if (remaining < decay) {
      return (remaining / decay).clamp(0.0, 1.0);
    }
    return 1.0;
  }

  static void _writeString(ByteData byteData, int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      byteData.setUint8(offset + i, s.codeUnitAt(i));
    }
  }
}

