import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class SignerClient {
  // Node signer endpoint (running locally)
  static const String signerUrl = 'http://localhost:3000/sign';

  /// Sends manifest.json to backend and gets signature back
  static Future<Uint8List> signManifest(Uint8List manifestBytes) async {
    try {
      // First attempt: send as raw octet-stream
      final primary = await http.post(
        Uri.parse(signerUrl),
        headers: {
          'Content-Type': 'application/octet-stream',
          'Accept': 'application/octet-stream,application/json',
        },
        body: manifestBytes,
      );

      if (primary.statusCode == 200) {
        // If server replied JSON, try to parse base64 signature field
        final ct = primary.headers['content-type'] ?? '';
        if (ct.contains('application/json')) {
          final jsonBody = json.decode(utf8.decode(primary.bodyBytes));
          final sigB64 = jsonBody['signature'] ?? jsonBody['signatureBase64'];
          if (sigB64 is String) {
            final bytes = Uint8List.fromList(base64.decode(sigB64));
            log('✅ Signer success (JSON). Signature bytes: ${bytes.length}');
            return bytes;
          }
        }
        log('✅ Signer success (raw). Signature bytes: ${primary.bodyBytes.length}');
        return primary.bodyBytes;
      }

      // Fallback attempt: send JSON with base64 manifest
      final fallbackBody = json.encode({
        'passData': {
          'manifest': base64.encode(manifestBytes),
          'encoding': 'base64',
        }
      });
      final fallback = await http.post(
        Uri.parse(signerUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/octet-stream,application/json',
        },
        body: fallbackBody,
      );

      if (fallback.statusCode == 200) {
        final ct = fallback.headers['content-type'] ?? '';
        if (ct.contains('application/json')) {
          final jsonBody = json.decode(utf8.decode(fallback.bodyBytes));
          final sigB64 = jsonBody['signature'] ?? jsonBody['signatureBase64'];
          if (sigB64 is String) {
            final bytes = Uint8List.fromList(base64.decode(sigB64));
            log('✅ Signer fallback success (JSON). Signature bytes: ${bytes.length}');
            return bytes;
          }
          throw Exception('Signer returned JSON but no signature field found');
        }
        log('✅ Signer fallback success (raw). Signature bytes: ${fallback.bodyBytes.length}');
        return fallback.bodyBytes;
      }

      final snippet = (primary.body.isNotEmpty ? primary.body : fallback.body);
      final short = snippet.length > 200 ? '${snippet.substring(0, 200)}...' : snippet;
      throw Exception('Signer failed. primary=${primary.statusCode}, fallback=${fallback.statusCode}. Body: $short');
    } catch (e) {
      throw Exception('Failed to sign manifest: $e');
    }
  }
}
