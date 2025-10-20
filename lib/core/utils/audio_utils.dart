import 'dart:typed_data';

// Convert a byte array of 16-bit PCM audio samples to a Float32List
Float32List convertBytesToFloat32List(
  Uint8List bytes, [
  endian = Endian.little,
]) {
  final values = Float32List(bytes.length ~/ 2);

  final data = ByteData.view(bytes.buffer);

  for (var i = 0; i < bytes.length; i += 2) {
    int short = data.getInt16(i, endian);
    values[i ~/ 2] = short / 32768.0;
  }

  return values;
}
