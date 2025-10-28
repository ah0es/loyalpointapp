import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'pass_builder.dart';
import 'manifest_generator.dart';
import 'signer_client.dart';
import 'zip_bundler.dart';

class PassGenerator {
  /// Generates complete .pkpass file
  static Future<Uint8List> generatePass({
    required String eventName,
    required String eventDate,
    String? barcodeMessage,
  }) async {
    log('🎫 Starting pass generation...');

    // ===== STEP 1: Load images from assets =====
    log('📷 Loading images...');
    final iconBytes = await _loadAsset('assets/images/apple_wallet/icon.png');
    final icon2xBytes = await _loadAsset('assets/images/apple_wallet/icon@2x.png');
    final Uint8List? icon3xBytes = await _tryLoadAsset('assets/images/apple_wallet/icon@3x.png');
    final logoBytes = await _loadAsset('assets/images/apple_wallet/logo.png');
    final logo2xBytes = await _loadAsset('assets/images/apple_wallet/logo@2x.png');
    final Uint8List? logo3xBytes = await _tryLoadAsset('assets/images/apple_wallet/logo@3x.png');

    // ===== STEP 2: Create pass.json =====
    log('📝 Creating pass.json...');
    final serialNumber = 'ticket-${DateTime.now().millisecondsSinceEpoch}';
    final passData = PassBuilder.createPassJson(
      serialNumber: serialNumber,
      description: 'Event Ticket',
      eventName: eventName,
      eventDate: eventDate,
      barcodeMessage: barcodeMessage ?? serialNumber,
    );
    final passJsonBytes = Uint8List.fromList(PassBuilder.toJsonBytes(passData));

    // ===== STEP 3: Generate manifest.json (SHA-1 hashes) =====
    log('🔍 Generating manifest.json...');
    final manifest = ManifestGenerator.createManifest(
      passJsonBytes: passJsonBytes,
      iconBytes: iconBytes,
      icon2xBytes: icon2xBytes,
      logoBytes: logoBytes,
      logo2xBytes: logo2xBytes,
      icon3xBytes: icon3xBytes,
      logo3xBytes: logo3xBytes,
    );
    final manifestBytes = Uint8List.fromList(ManifestGenerator.toJsonBytes(manifest));

    // ===== STEP 4: Sign manifest (call backend) =====
    log('✍️ Signing manifest...');
    final signatureBytes = await SignerClient.signManifest(manifestBytes);

    // ===== STEP 5: Bundle into .pkpass ZIP =====
    log('📦 Creating .pkpass ZIP...');
    final pkpassBytes = ZipBundler.createPkpass(
      passJsonBytes: passJsonBytes,
      manifestBytes: manifestBytes,
      signatureBytes: signatureBytes,
      iconBytes: iconBytes,
      icon2xBytes: icon2xBytes,
      logoBytes: logoBytes,
      logo2xBytes: logo2xBytes,
      icon3xBytes: icon3xBytes,
      logo3xBytes: logo3xBytes,
    );

    log('✅ Pass generated: ${pkpassBytes.length} bytes');
    return pkpassBytes;
  }

  /// Loads asset file as bytes
  static Future<Uint8List> _loadAsset(String path) async {
    final byteData = await rootBundle.load(path);
    return byteData.buffer.asUint8List();
  }

  static Future<Uint8List?> _tryLoadAsset(String path) async {
    try {
      final byteData = await rootBundle.load(path);
      return byteData.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}
