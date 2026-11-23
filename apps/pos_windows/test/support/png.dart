import 'dart:io';
import 'dart:typed_data';

int _crc(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c ^= b;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? (c >> 1) ^ 0xEDB88320 : c >> 1;
    }
  }
  return c ^ 0xFFFFFFFF;
}

Uint8List _chunk(String type, List<int> data) {
  final body = [...type.codeUnits, ...data];
  final crc = _crc(body);
  return Uint8List.fromList([
    (data.length >> 24) & 255,
    (data.length >> 16) & 255,
    (data.length >> 8) & 255,
    data.length & 255,
    ...body,
    (crc >> 24) & 255,
    (crc >> 16) & 255,
    (crc >> 8) & 255,
    crc & 255,
  ]);
}

/// A real, decodable PNG of one solid color ([rgb]) and the given size.
Uint8List makePng(int w, int h, {int rgb = 0xC0392B}) {
  final row = [
    0,
    for (var x = 0; x < w; x++) ...[
      (rgb >> 16) & 255,
      (rgb >> 8) & 255,
      rgb & 255,
    ],
  ];
  final raw = [for (var y = 0; y < h; y++) ...row];
  final ihdr = [
    (w >> 24) & 255,
    (w >> 16) & 255,
    (w >> 8) & 255,
    w & 255,
    (h >> 24) & 255,
    (h >> 16) & 255,
    (h >> 8) & 255,
    h & 255,
    8,
    2,
    0,
    0,
    0,
  ];
  return Uint8List.fromList([
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    ..._chunk('IHDR', ihdr),
    ..._chunk('IDAT', ZLibEncoder().convert(raw)),
    ..._chunk('IEND', const []),
  ]);
}
