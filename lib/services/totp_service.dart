import 'dart:typed_data';

/// Pure-Dart TOTP (RFC 6238) generator.
///
/// Implements Base32 decoding, HMAC-SHA1 and the HOTP/TOTP algorithms without
/// relying on any external package, so it works offline and adds no
/// dependencies to the project.
class TotpService {
  /// Default TOTP time step (seconds).
  static const int defaultPeriod = 30;

  /// Default number of digits produced.
  static const int defaultDigits = 6;

  /// Generates a TOTP code for [secret] (Base32 encoded).
  ///
  /// Returns a zero-padded numeric string of length [digits]. If the secret is
  /// empty or invalid, returns a string of dashes so the UI never crashes.
  static String generate(
    String secret, {
    int period = defaultPeriod,
    int digits = defaultDigits,
    DateTime? time,
  }) {
    final key = _base32Decode(secret);
    if (key.isEmpty) return '-' * digits;

    final now = (time ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final counter = now ~/ period;
    return _hotp(key, counter, digits: digits);
  }

  /// Same as [generate] but formatted for display, e.g. "482 091".
  static String generateFormatted(
    String secret, {
    int period = defaultPeriod,
    int digits = defaultDigits,
    DateTime? time,
  }) {
    final code = generate(secret, period: period, digits: digits, time: time);
    return formatCode(code);
  }

  /// Inserts a space in the middle of the code for readability, e.g.
  /// "482091" -> "482 091".
  static String formatCode(String code) {
    if (code.length <= 4) return code;
    final mid = code.length ~/ 2;
    return '${code.substring(0, mid)} ${code.substring(mid)}';
  }

  /// Seconds remaining in the current TOTP window (1..period).
  static int secondsRemaining({int period = defaultPeriod, DateTime? time}) {
    final now = (time ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    return period - (now % period);
  }

  // ---- HOTP (RFC 4226) --------------------------------------------------

  static String _hotp(Uint8List key, int counter, {required int digits}) {
    final counterBytes = Uint8List(8);
    var value = counter;
    for (var i = 7; i >= 0; i--) {
      counterBytes[i] = value & 0xff;
      value >>= 8;
    }

    final hash = _hmacSha1(key, counterBytes);
    final offset = hash[hash.length - 1] & 0x0f;
    final binary =
        ((hash[offset] & 0x7f) << 24) |
        ((hash[offset + 1] & 0xff) << 16) |
        ((hash[offset + 2] & 0xff) << 8) |
        (hash[offset + 3] & 0xff);

    final otp = binary % _pow10(digits);
    return otp.toString().padLeft(digits, '0');
  }

  static int _pow10(int n) {
    var result = 1;
    for (var i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }

  // ---- HMAC-SHA1 --------------------------------------------------------

  static Uint8List _hmacSha1(Uint8List key, Uint8List message) {
    const blockSize = 64;
    var k = key;
    if (k.length > blockSize) {
      k = _sha1(k);
    }
    if (k.length < blockSize) {
      final padded = Uint8List(blockSize);
      padded.setRange(0, k.length, k);
      k = padded;
    }

    final oKeyPad = Uint8List(blockSize);
    final iKeyPad = Uint8List(blockSize);
    for (var i = 0; i < blockSize; i++) {
      oKeyPad[i] = k[i] ^ 0x5c;
      iKeyPad[i] = k[i] ^ 0x36;
    }

    final inner = _sha1(_concat(iKeyPad, message));
    return _sha1(_concat(oKeyPad, inner));
  }

  static Uint8List _concat(Uint8List a, Uint8List b) {
    final out = Uint8List(a.length + b.length);
    out.setRange(0, a.length, a);
    out.setRange(a.length, out.length, b);
    return out;
  }

  // ---- SHA-1 ------------------------------------------------------------

  static Uint8List _sha1(Uint8List data) {
    var h0 = 0x67452301;
    var h1 = 0xEFCDAB89;
    var h2 = 0x98BADCFE;
    var h3 = 0x10325476;
    var h4 = 0xC3D2E1F0;

    final originalLengthBits = data.length * 8;

    // Pre-processing: append 0x80, pad with zeros, append 64-bit length.
    final paddingLength = ((56 - (data.length + 1) % 64) + 64) % 64;
    final totalLength = data.length + 1 + paddingLength + 8;
    final msg = Uint8List(totalLength);
    msg.setRange(0, data.length, data);
    msg[data.length] = 0x80;

    for (var i = 0; i < 8; i++) {
      msg[totalLength - 1 - i] = (originalLengthBits >> (8 * i)) & 0xff;
    }

    final w = List<int>.filled(80, 0);
    for (var chunk = 0; chunk < totalLength; chunk += 64) {
      for (var i = 0; i < 16; i++) {
        final j = chunk + i * 4;
        w[i] =
            ((msg[j] << 24) |
                (msg[j + 1] << 16) |
                (msg[j + 2] << 8) |
                msg[j + 3]) &
            0xffffffff;
      }
      for (var i = 16; i < 80; i++) {
        w[i] = _rotl(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
      }

      var a = h0;
      var b = h1;
      var c = h2;
      var d = h3;
      var e = h4;

      for (var i = 0; i < 80; i++) {
        int f;
        int k;
        if (i < 20) {
          f = (b & c) | (~b & d);
          k = 0x5A827999;
        } else if (i < 40) {
          f = b ^ c ^ d;
          k = 0x6ED9EBA1;
        } else if (i < 60) {
          f = (b & c) | (b & d) | (c & d);
          k = 0x8F1BBCDC;
        } else {
          f = b ^ c ^ d;
          k = 0xCA62C1D6;
        }

        final temp = (_rotl(a, 5) + f + e + k + w[i]) & 0xffffffff;
        e = d;
        d = c;
        c = _rotl(b, 30);
        b = a;
        a = temp;
      }

      h0 = (h0 + a) & 0xffffffff;
      h1 = (h1 + b) & 0xffffffff;
      h2 = (h2 + c) & 0xffffffff;
      h3 = (h3 + d) & 0xffffffff;
      h4 = (h4 + e) & 0xffffffff;
    }

    final out = Uint8List(20);
    _writeUint32(out, 0, h0);
    _writeUint32(out, 4, h1);
    _writeUint32(out, 8, h2);
    _writeUint32(out, 12, h3);
    _writeUint32(out, 16, h4);
    return out;
  }

  static void _writeUint32(Uint8List out, int offset, int value) {
    out[offset] = (value >> 24) & 0xff;
    out[offset + 1] = (value >> 16) & 0xff;
    out[offset + 2] = (value >> 8) & 0xff;
    out[offset + 3] = value & 0xff;
  }

  static int _rotl(int value, int shift) {
    value &= 0xffffffff;
    return ((value << shift) | (value >> (32 - shift))) & 0xffffffff;
  }

  // ---- Base32 (RFC 4648) ------------------------------------------------

  static const String _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// Decodes a Base32 string (case-insensitive, ignores spaces and padding).
  /// Returns an empty list if the input contains invalid characters.
  static Uint8List _base32Decode(String input) {
    final cleaned = input
        .toUpperCase()
        .replaceAll('=', '')
        .replaceAll(' ', '')
        .replaceAll('-', '');
    if (cleaned.isEmpty) return Uint8List(0);

    final bytes = <int>[];
    var buffer = 0;
    var bitsLeft = 0;
    for (final char in cleaned.codeUnits) {
      final index = _alphabet.indexOf(String.fromCharCode(char));
      if (index < 0) return Uint8List(0); // Invalid character.
      buffer = (buffer << 5) | index;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        bitsLeft -= 8;
        bytes.add((buffer >> bitsLeft) & 0xff);
      }
    }
    return Uint8List.fromList(bytes);
  }
}
