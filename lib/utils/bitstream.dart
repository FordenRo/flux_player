import 'dart:math';
import 'dart:typed_data';

/// Allows bit reading and writing
class BitStream {
  var _stream = <int>[];
  var _bitLength = 0;

  int get length => _bitLength;

  /// Cursor position in bits
  var cursor = 0;

  /// Initialises with an empty stream or with [bytes]
  BitStream({Uint8List? bytes}) {
    if (bytes != null) {
      _stream = bytes;
      _bitLength = _stream.length * 8;
    }
  }

  /// Gets the current stream
  Uint8List toBytes() => .fromList(_stream);

  /// Writes an int to the stream of length [bytes] and [bits]
  void write(int input, int bits) {
    var len = bits;
    var all = pow(2, len).toInt() - 1;
    input = input & all;
    var thisByte = _bitLength ~/ 8;
    var thisBit = _bitLength % 8;
    while (len > 0) {
      var thisLen = min(len, 8 - thisBit);
      if (thisByte + 1 > _stream.length) {
        _stream.add(0);
      }
      var shiftAmt = 8 - (thisBit + len);
      _stream[thisByte] =
          _stream[thisByte] |
          (shiftAmt > 0 ? (input << shiftAmt) : (input >> (0 - shiftAmt)));
      _stream[thisByte] = 255 & _stream[thisByte];
      len -= thisLen;
      _bitLength += thisLen;
      thisBit = 0;
      thisByte++;
    }
  }

  /// Writes a bool to the stream
  void writeBool(bool input) {
    write((input ? 1 : 0), 1);
  }

  /// Writes a byte array to the stream of length [bytes] and [bits]
  void writeBytes(Uint8List input, int bits) {
    var len = bits;
    var totBytes = len ~/ 8;
    var remBits = len % 8;

    var numBytes = input.lengthInBytes;
    if (remBits > 0) {
      var firstByte = (numBytes - totBytes) - 1;
      write(input[firstByte], remBits);
    }
    for (var x = numBytes - totBytes; x < numBytes; x++) {
      write(input[x], 8);
    }
  }

  /// Returns the current stream
  @override
  String toString() =>
      _stream.fold('', (v, e) => v += e.toRadixString(2).padLeft(8, '0'));

  /// Reads an int from the stream of length [bits]
  int read(int bits) {
    var len = bits;
    var thisByte = cursor ~/ 8;
    var thisBit = cursor % 8;
    var output = 0;
    while (len > 0) {
      var thisLen = min(len, 8 - thisBit);
      var all = pow(2, thisLen).toInt() - 1;
      var bit = _stream[thisByte];
      if (thisBit + thisLen < 8) {
        bit = bit >> (8 - (thisBit + thisLen));
      }
      output = output << thisLen | (bit & all);
      len -= thisLen;
      cursor += thisLen;
      thisBit = 0;
      thisByte++;
    }
    return output;
  }

  /// Reads a bool from the stream
  bool readBool() => read(1) == 1;

  /// Reads an ASCII string from the stream of length [bytes] and [bits]
  String readAsciiString(int length) {
    try {
      return String.fromCharCodes(readBytes(length * 8));
    } catch (e) {
      return '';
    }
  }

  String readString(int bits) {
    var length = read(bits);
    try {
      return String.fromCharCodes(
        Uint16List.fromList(List.generate(length, (i) => read(16))),
      );
    } catch (e) {
      return '';
    }
  }

  /// Writes an ASCII string to the stream of length [bytes] and [bits]
  void writeAsciiString(String input, int length) {
    writeBytes(Uint8List.fromList(input.codeUnits), length * 8);
  }

  void writeString(String input, int bits) {
    var bytes = Uint16List.fromList(input.codeUnits);
    write(bytes.length, bits);
    for (var e in bytes) {
      write(e, 16);
    }
  }

  /// Checks if [bit] is set or not
  bool checkBit(int bit) {
    bit = (_bitLength - bit) - 1;
    var thisByte = bit ~/ 8;
    var thisBit = bit % 8;
    return (_stream[thisByte] & (1 << (7 - thisBit))) != 0;
  }

  bool canRead(int bits) => cursor + bits <= _bitLength;

  /// Reads a byte array from the stream of length [bytes] and [bits]
  Uint8List readBytes(int bits) {
    var len = bits;
    var totBytes = len ~/ 8;
    var remBits = len % 8;
    var op = <int>[];
    if (remBits > 0) {
      op.add(read(remBits));
    }
    for (var i = 0; i < totBytes; i++) {
      op.add(read(8));
    }
    return .fromList(op);
  }

  /// Reads a BitStream object from the stream of length [bytes] and [bits]
  BitStream readBitStream(int bits) {
    var op = BitStream();
    op.writeBytes(readBytes(bits), bits);
    return op;
  }

  /// Reads a BitStream object from the stream of length [bytes] and [bits]
  void writeBitStream(BitStream input, int bits) =>
      writeBytes(input.readBytes(bits), bits);
}
