import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class ManifestGenerator {
  /// Generates manifest.json with SHA-1 hashes of all files
  static Map<String, String> createManifest({
    required Uint8List passJsonBytes,
    required Uint8List iconBytes,
    required Uint8List icon2xBytes,
    required Uint8List logoBytes,
    required Uint8List logo2xBytes,
    Uint8List? icon3xBytes,
    Uint8List? logo3xBytes,
  }) {
    final manifest = <String, String>{
      'pass.json': _sha1Hash(passJsonBytes),
      'icon.png': _sha1Hash(iconBytes),
      'icon@2x.png': _sha1Hash(icon2xBytes),
      'logo.png': _sha1Hash(logoBytes),
      'logo@2x.png': _sha1Hash(logo2xBytes),
    };

    if (icon3xBytes != null && icon3xBytes.isNotEmpty) {
      manifest['icon@3x.png'] = _sha1Hash(icon3xBytes);
    }
    if (logo3xBytes != null && logo3xBytes.isNotEmpty) {
      manifest['logo@3x.png'] = _sha1Hash(logo3xBytes);
    }

    return manifest;
  }

  /// Calculates SHA-1 hash of bytes
  static String _sha1Hash(Uint8List bytes) {
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  /// Converts manifest to JSON bytes
  static List<int> toJsonBytes(Map<String, String> manifest) {
    return utf8.encode(json.encode(manifest));
  }
}
