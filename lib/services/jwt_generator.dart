import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:pointycastle/export.dart';
import '../models/service_account.dart';

/// JWT Generator for Google Wallet
///
/// Implements RSA-SHA256 signing for JWT tokens required by Google Wallet API
/// Handles PEM private key parsing and JWT creation with proper Base64URL encoding
class JWTGenerator {
  final ServiceAccount _serviceAccount;

  JWTGenerator(this._serviceAccount);

  /// Generate JWT for Google Wallet Save to Wallet
  ///
  /// Creates a JWT token that allows users to add loyalty cards to Google Wallet
  /// The JWT contains the loyalty card data and is signed with the service account private key
  Future<String> generateSaveToWalletJWT(Map<String, dynamic> loyaltyCardObject) async {
    try {
      log('🔐 Generating JWT for Google Wallet...');

      // Create JWT header
      final header = {'alg': 'RS256', 'typ': 'JWT'};

      // Create JWT payload
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final payload = {
        'iss': _serviceAccount.serviceAccountEmail,
        'aud': 'google',
        'typ': 'savetowallet',
        'iat': currentTime,
        'payload': {
          'genericObjects': [loyaltyCardObject],
        },
      };

      log('📝 JWT Header: ${jsonEncode(header)}');
      log('📝 JWT Payload (first 50 chars): ${jsonEncode(payload).substring(0, 50)}...');
      log('📝 Full JWT Payload: ${jsonEncode(payload)}');

      // Encode header and payload
      final encodedHeader = _base64UrlEncode(jsonEncode(header));
      final encodedPayload = _base64UrlEncode(jsonEncode(payload));

      // Create the message to sign
      final message = '$encodedHeader.$encodedPayload';

      // Sign the message with RSA-SHA256
      final signature = await _signWithRSA(message);

      // Create the complete JWT
      final jwt = '$message.$signature';

      log('✅ JWT generated successfully (length: ${jwt.length})');
      return jwt;
    } catch (e) {
      log('❌ Error generating JWT: $e');
      rethrow;
    }
  }

  /// Generate JWT for OAuth token exchange
  ///
  /// Creates a JWT token for obtaining OAuth access tokens
  /// Used for updating loyalty cards via Google Wallet API
  Future<String> generateOAuthJWT(String scope) async {
    try {
      log('🔐 Generating OAuth JWT...');

      final header = {'alg': 'RS256', 'typ': 'JWT'};

      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final payload = {
        'iss': _serviceAccount.serviceAccountEmail,
        'scope': scope,
        'aud': 'https://oauth2.googleapis.com/token',
        'iat': currentTime,
        'exp': currentTime + 3600, // 1 hour expiration
      };

      log('📝 OAuth JWT Header: ${jsonEncode(header)}');
      log('📝 OAuth JWT Payload: ${jsonEncode(payload)}');

      final encodedHeader = _base64UrlEncode(jsonEncode(header));
      final encodedPayload = _base64UrlEncode(jsonEncode(payload));
      final message = '$encodedHeader.$encodedPayload';

      final signature = await _signWithRSA(message);
      final jwt = '$message.$signature';

      log('✅ OAuth JWT generated successfully');
      return jwt;
    } catch (e) {
      log('❌ Error generating OAuth JWT: $e');
      rethrow;
    }
  }

  /// Sign message with RSA-SHA256 using the service account private key
  Future<String> _signWithRSA(String message) async {
    try {
      log('🔑 Parsing RSA private key...');

      // Parse the private key from PEM format
      final privateKey = _parsePrivateKey();

      // Create RSA signer
      final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
      signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

      // Convert message to bytes
      final messageBytes = Uint8List.fromList(utf8.encode(message));

      // Sign the message
      final signature = signer.generateSignature(messageBytes);

      // Convert signature to bytes
      final signatureBytes = signature.bytes;

      // Encode signature as Base64URL
      final encodedSignature = _base64UrlEncode(signatureBytes);

      log('✅ RSA signature generated');
      return encodedSignature;
    } catch (e) {
      log('❌ Error signing with RSA: $e');
      rethrow;
    }
  }

  /// Parse RSA private key from PEM format
  ///
  /// Extracts the RSA private key components from the PEM-encoded private key
  /// Returns an RSAPrivateKey object for signing
  RSAPrivateKey _parsePrivateKey() {
    try {
      // Remove PEM headers and decode base64
      final pemContent = _serviceAccount.privateKey
          .replaceAll('-----BEGIN PRIVATE KEY-----', '')
          .replaceAll('-----END PRIVATE KEY-----', '')
          .replaceAll('\n', '')
          .replaceAll('\r', '');

      final keyBytes = base64Decode(pemContent);

      // Parse ASN.1 structure
      final asn1Parser = ASN1Parser(keyBytes);
      final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

      log('🔍 Top level sequence has ${topLevelSeq.elements.length} elements');

      // The PKCS#8 structure is:
      // SEQUENCE {
      //   version INTEGER,
      //   privateKeyAlgorithm SEQUENCE,
      //   privateKey OCTET STRING
      // }

      // Extract the private key octet string (third element)
      final privateKeyOctetString = topLevelSeq.elements[2] as ASN1OctetString;
      final privateKeyBytes = privateKeyOctetString.octets;

      log('🔍 Private key octet string length: ${privateKeyBytes.length} bytes');

      // Parse the private key octet string as ASN.1
      final privateKeyParser = ASN1Parser(privateKeyBytes);
      final rsaPrivateKeySeq = privateKeyParser.nextObject() as ASN1Sequence;

      log('🔍 RSA private key sequence has ${rsaPrivateKeySeq.elements.length} elements');

      // The RSA private key structure is:
      // SEQUENCE {
      //   version INTEGER (index 0),
      //   modulus INTEGER (index 1),
      //   publicExponent INTEGER (index 2),
      //   privateExponent INTEGER (index 3),
      //   prime1 INTEGER (index 4),
      //   prime2 INTEGER (index 5),
      //   exponent1 INTEGER (index 6),
      //   exponent2 INTEGER (index 7),
      //   coefficient INTEGER (index 8)
      // }

      // Extract RSA components (indices 1, 3, 4, 5)
      final modulus = (rsaPrivateKeySeq.elements[1] as ASN1Integer).valueAsBigInteger;
      final privateExponent = (rsaPrivateKeySeq.elements[3] as ASN1Integer).valueAsBigInteger;
      final p = (rsaPrivateKeySeq.elements[4] as ASN1Integer).valueAsBigInteger;
      final q = (rsaPrivateKeySeq.elements[5] as ASN1Integer).valueAsBigInteger;

      log('🔍 Extracted RSA components:');
      log('🔍   Modulus: ${modulus.bitLength} bits');
      log('🔍   Private exponent: ${privateExponent.bitLength} bits');
      log('🔍   P: ${p.bitLength} bits');
      log('🔍   Q: ${q.bitLength} bits');

      // Create RSA private key
      final rsaPrivateKey = RSAPrivateKey(modulus, privateExponent, p, q);

      log('✅ RSA private key parsed successfully');
      return rsaPrivateKey;
    } catch (e) {
      log('❌ Error parsing private key: $e');
      rethrow;
    }
  }

  /// Encode data as Base64URL (RFC 4648)
  ///
  /// Base64URL encoding is required for JWT tokens
  /// Removes padding and uses URL-safe characters
  String _base64UrlEncode(dynamic data) {
    String encoded;

    if (data is String) {
      encoded = base64Encode(utf8.encode(data));
    } else if (data is List<int>) {
      encoded = base64Encode(data);
    } else {
      throw ArgumentError('Unsupported data type for Base64URL encoding');
    }

    // Convert to Base64URL format
    return encoded.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', ''); // Remove padding
  }
}
