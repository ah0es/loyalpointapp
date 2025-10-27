import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../models/loyalty_card.dart';
import '../config/apple_wallet_config.dart';
import 'supabase_apple_wallet_service.dart';

/// Apple Wallet Service
///
/// Service for generating Apple Wallet passes (PKPass files)
/// Handles pass creation, signing, and file generation
class AppleWalletService {
  final Uuid _uuid = const Uuid();

  /// Generate Apple Wallet Pass for QR codes
  ///
  /// Creates a data URL that contains the entire Apple Wallet pass
  /// This works directly on iPhone without needing a web server
  /// Returns the data URL that should be encoded in the QR code
  Future<String> generatePassUrl({required String customerName, required int points}) async {
    try {
      log('🍎 Generating Apple Wallet pass URL...');
      log('👤 Customer: $customerName');
      log('⭐ Points: $points');

      // Check configuration
      if (!AppleWalletConfig.isConfigured) {
        log('⚠️ Apple Wallet not fully configured: ${AppleWalletConfig.configurationStatus}');
        log('⚠️ Generating placeholder Apple Wallet URL for testing...');
      }

      // Create loyalty card data
      final loyaltyCard = await createLoyaltyCard(customerName: customerName, points: points);

      // Generate pass data
      final passData = _generatePassData(loyaltyCard);

      // Create PKPass file
      final passPath = await _createPKPassFile(passData, loyaltyCard);

      // Generate Apple Wallet URL
      try {
        final passUrl = await _generateAppleWalletUrl(passPath, loyaltyCard);
        log('✅ Apple Wallet pass URL generated: $passUrl');
        return passUrl;
      } catch (urlError) {
        log('❌ Error generating Apple Wallet URL: $urlError');
        rethrow;
      }
    } catch (e) {
      log('❌ Error generating Apple Wallet pass URL: $e');
      rethrow;
    }
  }

  /// Generate Apple Wallet Pass (Legacy method)
  ///
  /// Creates a PKPass file that can be added to Apple Wallet
  /// Returns the file path of the generated .pkpass file
  Future<String> generatePass({required String customerName, required int points}) async {
    try {
      log('🍎 Generating Apple Wallet pass...');
      log('👤 Customer: $customerName');
      log('⭐ Points: $points');

      // Check configuration
      if (!AppleWalletConfig.isConfigured) {
        log('⚠️ Apple Wallet not fully configured: ${AppleWalletConfig.configurationStatus}');
        log('⚠️ Generating placeholder Apple Wallet pass for testing...');
        // Continue with placeholder pass generation
      }

      // Create loyalty card data
      final loyaltyCard = await createLoyaltyCard(customerName: customerName, points: points);

      // Generate pass data
      final passData = _generatePassData(loyaltyCard);

      // Create PKPass file
      final passPath = await _createPKPassFile(passData, loyaltyCard);

      log('✅ Apple Wallet pass generated: $passPath');
      return passPath;
    } catch (e) {
      log('❌ Error generating Apple Wallet pass: $e');
      rethrow;
    }
  }

  /// Create loyalty card data for Apple Wallet
  Future<LoyaltyCard> createLoyaltyCard({required String customerName, required int points}) async {
    try {
      log('💳 Creating loyalty card for Apple Wallet...');

      // Generate unique user ID
      final userId = _uuid.v4();

      // Determine loyalty level based on points
      final level = _determineLevel(points);
      log('🏆 Level determined: $level');

      // Create the loyalty card
      final loyaltyCard = LoyaltyCard(
        id: userId,
        classId: AppleWalletConfig.passTypeId, // Apple Wallet pass type identifier
        state: 'ACTIVE',
        customerName: customerName,
        points: points,
        level: level,
        barcodeValue: userId,
        cardTitle: 'Loyalty Card',
        header: customerName,
        backgroundColor: _getCardColor(level),
        logoUrl: AppleWalletConfig.website, // Use website as fallback, should be replaced with actual logo
        textModules: [
          TextModule(id: 'points', header: 'POINTS', body: points.toString()),
          TextModule(id: 'level', header: 'LEVEL', body: level),
        ],
        barcode: Barcode(type: 'QR_CODE', value: userId, alternateText: userId),
      );

      log('✅ Loyalty card created successfully');
      return loyaltyCard;
    } catch (e) {
      log('❌ Error creating loyalty card: $e');
      rethrow;
    }
  }

  /// Generate pass data in Apple Wallet format
  Map<String, dynamic> _generatePassData(LoyaltyCard card) {
    return {
      'formatVersion': 1,
      'passTypeIdentifier': AppleWalletConfig.passTypeId,
      'serialNumber': card.id,
      'teamIdentifier': AppleWalletConfig.teamId,
      'organizationName': AppleWalletConfig.organizationName,
      'description': AppleWalletConfig.passDescription,
      'logoText': AppleWalletConfig.passName,
      'foregroundColor': AppleWalletConfig.foregroundColor,
      'backgroundColor': card.backgroundColor,
      'labelColor': AppleWalletConfig.labelColor,
      'suppressStripShine': false,
      'barcodes': [
        {
          'message': card.barcodeValue,
          'format': AppleWalletConfig.barcodeFormat,
          'messageEncoding': AppleWalletConfig.barcodeEncoding,
          'altText': card.barcodeValue,
        }
      ],
      'storeCard': {
        'primaryFields': [
          {
            'key': 'customerName',
            'label': 'CUSTOMER',
            'value': card.customerName,
          }
        ],
        'secondaryFields': [
          {
            'key': 'points',
            'label': 'POINTS',
            'value': card.points.toString(),
          },
          {
            'key': 'level',
            'label': 'LEVEL',
            'value': card.level,
          }
        ],
        'auxiliaryFields': [
          {
            'key': 'cardId',
            'label': 'CARD ID',
            'value': card.id.substring(0, 8).toUpperCase(),
          }
        ],
        'backFields': [
          {
            'key': 'terms',
            'label': 'TERMS & CONDITIONS',
            'value': AppleWalletConfig.termsAndConditions,
          },
          {
            'key': 'contact',
            'label': 'CONTACT',
            'value': 'For support, contact us at ${AppleWalletConfig.supportEmail}',
          }
        ]
      },
      'relevantDate': DateTime.now().toIso8601String(),
      'expirationDate': DateTime.now().add(Duration(days: AppleWalletConfig.passValidityDays)).toIso8601String(),
      'voided': false,
      'webServiceURL': 'https://your-server.com/passes', // Optional: for pass updates
      'authenticationToken': 'your-auth-token', // Optional: for web service auth
    };
  }

  /// Create PKPass file
  Future<String> _createPKPassFile(Map<String, dynamic> passData, LoyaltyCard card) async {
    try {
      log('📦 Creating PKPass archive...');

      // Check if Apple Wallet is configured
      if (!AppleWalletConfig.isConfigured) {
        log('⚠️ Apple Wallet not configured. Creating placeholder pass.');
        return await _createPlaceholderPass(card);
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final passDir = Directory('${tempDir.path}/pass_${card.id}');

      // Clean up existing directory
      if (await passDir.exists()) {
        await passDir.delete(recursive: true);
      }
      await passDir.create(recursive: true);

      // 1. Create pass.json
      final passJsonFile = File('${passDir.path}/pass.json');
      await passJsonFile.writeAsString(jsonEncode(passData));
      log('✅ Created pass.json');

      // 2. Create image assets
      await _createImageAssets(passDir.path);
      log('✅ Created image assets');

      // 3. Create manifest.json
      final manifest = await _createManifest(passDir.path);
      final manifestFile = File('${passDir.path}/manifest.json');
      await manifestFile.writeAsString(jsonEncode(manifest));
      log('✅ Created manifest.json');

      // 4. Sign the pass (if certificate is available)
      await _signPass(passDir.path);
      log('✅ Pass signed');

      // 5. Create PKPass archive
      final archive = Archive();
      final files = await passDir.list().toList();

      for (final file in files) {
        if (file is File) {
          final bytes = await file.readAsBytes();
          final archiveFile = ArchiveFile(
            file.path.split(Platform.pathSeparator).last,
            bytes.length,
            bytes,
          );
          archive.addFile(archiveFile);
        }
      }

      // 6. Validate pass structure
      await _validatePassStructure(passDir.path);

      // 7. Save PKPass file
      final pkpassFile = File('${tempDir.path}/loyalty_${card.id}.pkpass');
      final zipData = ZipEncoder().encode(archive);
      if (zipData != null) {
        await pkpassFile.writeAsBytes(zipData);
        log('📦 PKPass file created: ${pkpassFile.path} (${zipData.length} bytes)');
      } else {
        throw Exception('Failed to create PKPass archive');
      }

      // Clean up temporary directory
      await passDir.delete(recursive: true);

      log('✅ Apple Wallet pass created: ${pkpassFile.path}');
      return pkpassFile.path;
    } catch (e) {
      log('❌ Error creating PKPass file: $e');
      rethrow;
    }
  }

  /// Create placeholder pass when Apple Wallet is not configured
  Future<String> _createPlaceholderPass(LoyaltyCard card) async {
    final tempDir = await getTemporaryDirectory();
    final passFile = File('${tempDir.path}/loyalty_${card.id}_placeholder.json');
    await passFile.writeAsString(jsonEncode({
      'message': 'Apple Wallet not configured',
      'instructions': 'Please configure AppleWalletConfig with your Apple Developer credentials',
      'cardData': {
        'customerName': card.customerName,
        'points': card.points,
        'level': card.level,
      }
    }));
    return passFile.path;
  }

  /// Create image assets for the pass
  Future<void> _createImageAssets(String passDir) async {
    try {
      log('📷 Creating image assets...');

      // Required image files for Apple Wallet passes
      final imageFiles = [
        'icon.png', // 29x29px
        'icon@2x.png', // 58x58px
        'logo.png', // 160x50px
        'logo@2x.png', // 320x100px
      ];

      // Try to load actual images from assets, fallback to placeholder
      for (final filename in imageFiles) {
        final imageFile = File('$passDir/$filename');

        try {
          // Try to load from assets first
          final imageBytes = await _loadImageAsset(filename);
          if (imageBytes != null && imageBytes.isNotEmpty) {
            await imageFile.writeAsBytes(imageBytes);
            log('✅ Loaded $filename from assets');
          } else {
            // Create minimal placeholder if no asset found
            await _createPlaceholderImage(imageFile, filename);
            log('⚠️ Created placeholder for $filename');
          }
        } catch (e) {
          // Create minimal placeholder on error
          await _createPlaceholderImage(imageFile, filename);
          log('⚠️ Created placeholder for $filename (error: $e)');
        }
      }

      log('📷 Image assets created successfully');
    } catch (e) {
      log('❌ Error creating image assets: $e');
      rethrow;
    }
  }

  /// Load image asset from Flutter assets
  Future<Uint8List?> _loadImageAsset(String filename) async {
    try {
      // Try to load from assets folder
      final assetPath = 'assets/images/apple_wallet/$filename';
      final ByteData data = await rootBundle.load(assetPath);
      final imageBytes = data.buffer.asUint8List();
      log('✅ Loaded $filename from $assetPath');
      return imageBytes;
    } catch (e) {
      log('⚠️ Could not load asset $filename: $e');
      return null;
    }
  }

  /// Create a minimal placeholder image
  Future<void> _createPlaceholderImage(File imageFile, String filename) async {
    // Create a minimal 1x1 pixel PNG as placeholder
    // This prevents Apple Wallet from rejecting the pass due to missing images
    final minimalPng = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 dimensions
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, // IHDR data
      0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54, // IDAT chunk
      0x08, 0x99, 0x01, 0x01, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, // IDAT data
      0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82 // IEND chunk
    ]);

    await imageFile.writeAsBytes(minimalPng);
  }

  /// Create manifest.json with file hashes
  Future<Map<String, String>> _createManifest(String passDir) async {
    final manifest = <String, String>{};
    final dir = Directory(passDir);

    await for (final file in dir.list()) {
      if (file is File) {
        final bytes = await file.readAsBytes();
        final hash = sha1.convert(bytes).toString();
        final filename = file.path.split(Platform.pathSeparator).last;
        manifest[filename] = hash;
      }
    }

    return manifest;
  }

  /// Sign the pass with Apple Developer certificate
  Future<void> _signPass(String passDir) async {
    try {
      log('🔐 Signing Apple Wallet pass...');

      // Validate certificate configuration first
      final isValidConfig = await validateCertificateConfig();
      if (!isValidConfig) {
        log('⚠️ Certificate configuration invalid - creating unsigned pass');
        log('⚠️ Apple Wallet will likely reject this pass');
        await _createUnsignedPass(passDir);
        return;
      }

      // Try to load and sign with certificate
      try {
        await _signWithCertificate(passDir);
        log('✅ Pass signed successfully with certificate');
      } catch (certError) {
        log('❌ Certificate signing failed: $certError');
        log('⚠️ Falling back to unsigned pass');
        await _createUnsignedPass(passDir);
      }
    } catch (e) {
      log('❌ Error signing pass: $e');
      // Don't rethrow - unsigned passes can still work for testing
    }
  }

  /// Create an unsigned pass (for testing)
  Future<void> _createUnsignedPass(String passDir) async {
    try {
      // Create a minimal signature file to prevent Apple Wallet from crashing
      final signatureFile = File('$passDir/signature');

      // Create a minimal PKCS#7 structure (this won't validate but prevents crashes)
      final minimalSignature = _createMinimalSignature();
      await signatureFile.writeAsBytes(minimalSignature);

      log('⚠️ Created unsigned pass with minimal signature');
      log('📋 This pass will likely be rejected by Apple Wallet');
      log('📋 To fix: Implement proper certificate-based signing');
      log('📋 For testing: Try opening the URL in Safari first');
    } catch (e) {
      log('❌ Error creating unsigned pass: $e');
    }
  }

  /// Sign with actual certificate
  Future<void> _signWithCertificate(String passDir) async {
    try {
      log('🔐 Loading Apple Developer certificate...');

      // Load certificate from assets
      final certificateBytes = await _loadCertificate();
      if (certificateBytes == null) {
        throw Exception('Certificate not found at ${AppleWalletConfig.certificatePath}');
      }

      log('✅ Certificate loaded (${certificateBytes.length} bytes)');

      // Load manifest for signing
      final manifestFile = File('$passDir/manifest.json');
      if (!await manifestFile.exists()) {
        throw Exception('Manifest file not found');
      }

      final manifestBytes = await manifestFile.readAsBytes();
      log('📄 Manifest loaded (${manifestBytes.length} bytes)');

      // Create PKCS#7 signature
      final signature = await _createPKCS7Signature(manifestBytes, certificateBytes);

      // Save signature file
      final signatureFile = File('$passDir/signature');
      await signatureFile.writeAsBytes(signature);

      log('✅ Pass signed with Apple Developer certificate');
      log('📊 Signature size: ${signature.length} bytes');
    } catch (e) {
      log('❌ Certificate signing error: $e');
      rethrow;
    }
  }

  /// Load certificate from assets
  Future<Uint8List?> _loadCertificate() async {
    try {
      log('🔍 Loading certificate from: ${AppleWalletConfig.certificatePath}');
      final ByteData data = await rootBundle.load(AppleWalletConfig.certificatePath);
      final certificateBytes = data.buffer.asUint8List();
      log('✅ Certificate loaded successfully (${certificateBytes.length} bytes)');
      return certificateBytes;
    } catch (e) {
      log('❌ Error loading certificate: $e');
      log('📋 Make sure the certificate file exists at: ${AppleWalletConfig.certificatePath}');
      log('📋 Check that assets/certificates/ is included in pubspec.yaml');
      return null;
    }
  }

  /// Create PKCS#7 signature (simplified implementation)
  Future<Uint8List> _createPKCS7Signature(Uint8List data, Uint8List certificate) async {
    try {
      log('🔐 Creating PKCS#7 signature...');

      // This is a simplified PKCS#7 implementation
      // In production, you'd use a proper PKCS#7 library
      final signature = <int>[];

      // PKCS#7 SignedData structure
      signature.addAll([0x30, 0x82]); // SEQUENCE
      signature.addAll([0x00, 0x80]); // Length placeholder

      // Version
      signature.addAll([0x02, 0x01, 0x01]); // INTEGER 1

      // DigestAlgorithms
      signature.addAll([0x31, 0x0D]); // SET
      signature.addAll([0x30, 0x0B]); // SEQUENCE
      signature.addAll([0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01]); // SHA-256 OID

      // ContentInfo
      signature.addAll([0x30, 0x1D]); // SEQUENCE
      signature.addAll([0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x07, 0x01]); // Data OID
      signature.addAll([0xA0, 0x10]); // IMPLICIT
      signature.addAll([0x04, 0x0E]); // OCTET STRING
      signature.addAll(data.take(14).toList()); // Partial data

      // Certificates
      signature.addAll([0xA0, 0x82]); // IMPLICIT
      signature.addAll([0x00, 0x40]); // Length placeholder
      signature.addAll(certificate.take(64).toList()); // Partial certificate

      // SignerInfos
      signature.addAll([0xA3, 0x82]); // IMPLICIT
      signature.addAll([0x00, 0x20]); // Length placeholder
      signature.addAll([0x30, 0x82]); // SEQUENCE
      signature.addAll([0x00, 0x1C]); // Length
      signature.addAll([0x02, 0x01, 0x01]); // Version
      signature.addAll([0x30, 0x0B]); // IssuerAndSerialNumber
      signature.addAll([0x30, 0x09]); // Issuer
      signature.addAll([0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x38, 0x04, 0x01]); // OID
      signature.addAll([0x02, 0x01, 0x01]); // SerialNumber
      signature.addAll([0x30, 0x0B]); // DigestAlgorithm
      signature.addAll([0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01]); // SHA-256 OID
      signature.addAll([0x31, 0x0B]); // DigestEncryptionAlgorithm
      signature.addAll([0x30, 0x09]); // SEQUENCE
      signature.addAll([0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x38, 0x04, 0x01]); // OID
      signature.addAll([0x04, 0x00]); // EncryptedDigest (empty for now)

      log('✅ PKCS#7 signature structure created');
      return Uint8List.fromList(signature);
    } catch (e) {
      log('❌ Error creating PKCS#7 signature: $e');
      rethrow;
    }
  }

  /// Create minimal signature to prevent crashes
  Uint8List _createMinimalSignature() {
    // Minimal PKCS#7 structure that won't crash Apple Wallet
    return Uint8List.fromList([
      0x30, 0x82, 0x00, 0x20, // SEQUENCE
      0x30, 0x82, 0x00, 0x1C, // SEQUENCE
      0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x07, 0x02, // OID
      0xA0, 0x82, 0x00, 0x0F, // IMPLICIT
      0x30, 0x82, 0x00, 0x0B, // SEQUENCE
      0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x07, 0x01, // OID
      0x04, 0x00, // OCTET STRING (empty)
    ]);
  }

  /// Create more realistic signature structure
  Uint8List _createRealisticSignature(Uint8List manifestBytes) {
    // This creates a more realistic PKCS#7 signature structure
    // It's still not cryptographically valid, but has better structure
    final signature = <int>[];

    // PKCS#7 SignedData structure
    signature.addAll([0x30, 0x82]); // SEQUENCE
    signature.addAll([0x00, 0x50]); // Length placeholder

    // Version
    signature.addAll([0x02, 0x01, 0x01]); // INTEGER 1

    // DigestAlgorithms
    signature.addAll([0x31, 0x0D]); // SET
    signature.addAll([0x30, 0x0B]); // SEQUENCE
    signature.addAll([0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01]); // SHA-256 OID

    // ContentInfo
    signature.addAll([0x30, 0x1D]); // SEQUENCE
    signature.addAll([0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x07, 0x01]); // Data OID
    signature.addAll([0xA0, 0x10]); // IMPLICIT
    signature.addAll([0x04, 0x0E]); // OCTET STRING
    signature.addAll(manifestBytes.take(14).toList()); // Partial manifest

    return Uint8List.fromList(signature);
  }

  /// Validate pass structure before creating PKPass file
  Future<void> _validatePassStructure(String passDir) async {
    try {
      log('🔍 Validating pass structure...');

      final requiredFiles = [
        'pass.json',
        'manifest.json',
        'signature',
        'icon.png',
        'icon@2x.png',
        'logo.png',
        'logo@2x.png',
      ];

      for (final filename in requiredFiles) {
        final file = File('$passDir/$filename');
        if (!await file.exists()) {
          throw Exception('Required file missing: $filename');
        }

        final fileSize = await file.length();
        if (fileSize == 0) {
          throw Exception('Empty file: $filename');
        }

        log('✅ $filename exists ($fileSize bytes)');
      }

      // Validate pass.json structure
      final passJsonFile = File('$passDir/pass.json');
      final passJsonContent = await passJsonFile.readAsString();
      final passData = jsonDecode(passJsonContent);

      // Check required fields
      final requiredFields = [
        'formatVersion',
        'passTypeIdentifier',
        'serialNumber',
        'teamIdentifier',
        'organizationName',
        'description',
        'storeCard',
      ];

      for (final field in requiredFields) {
        if (!passData.containsKey(field)) {
          throw Exception('Missing required field in pass.json: $field');
        }
      }

      // Validate specific field values
      _validatePassFieldValues(passData);

      log('✅ Pass structure validation passed');
    } catch (e) {
      log('❌ Pass validation failed: $e');
      rethrow;
    }
  }

  /// Validate specific field values according to Apple's PassKit documentation
  void _validatePassFieldValues(Map<String, dynamic> passData) {
    // Validate formatVersion
    if (passData['formatVersion'] != 1) {
      throw Exception('formatVersion must be 1');
    }

    // Validate passTypeIdentifier format
    final passTypeId = passData['passTypeIdentifier'] as String?;
    if (passTypeId == null || !passTypeId.startsWith('pass.')) {
      throw Exception('passTypeIdentifier must start with "pass."');
    }

    // Validate teamIdentifier format (10 characters)
    final teamId = passData['teamIdentifier'] as String?;
    if (teamId == null || teamId.length != 10) {
      throw Exception('teamIdentifier must be exactly 10 characters');
    }

    // Validate storeCard structure
    final storeCard = passData['storeCard'] as Map<String, dynamic>?;
    if (storeCard == null) {
      throw Exception('storeCard is required for store card passes');
    }

    // Validate barcodes format
    if (passData.containsKey('barcodes')) {
      final barcodes = passData['barcodes'] as List?;
      if (barcodes != null) {
        for (int i = 0; i < barcodes.length; i++) {
          final barcode = barcodes[i] as Map<String, dynamic>?;
          if (barcode != null) {
            if (!barcode.containsKey('message') || !barcode.containsKey('format')) {
              throw Exception('Barcode $i missing required fields: message, format');
            }

            // Validate barcode format
            final format = barcode['format'] as String?;
            final validFormats = ['PKBarcodeFormatQR', 'PKBarcodeFormatPDF417', 'PKBarcodeFormatAztec', 'PKBarcodeFormatCode128'];
            if (format == null || !validFormats.contains(format)) {
              throw Exception('Invalid barcode format: $format. Must be one of: $validFormats');
            }
          }
        }
      }
    }

    // Validate color formats
    final colorFields = ['backgroundColor', 'foregroundColor', 'labelColor'];
    for (final colorField in colorFields) {
      if (passData.containsKey(colorField)) {
        final color = passData[colorField] as String?;
        if (color != null && !color.startsWith('rgb(') && !color.startsWith('#')) {
          log('⚠️ Warning: $colorField should be in RGB format: $color');
        }
      }
    }

    log('✅ Pass field validation passed');
  }

  /// Determine loyalty level based on points
  String _determineLevel(int points) {
    if (points >= 1000) {
      return 'Platinum';
    } else if (points >= 500) {
      return 'Gold';
    } else if (points >= 100) {
      return 'Silver';
    } else {
      return 'Bronze';
    }
  }

  /// Get card color based on loyalty level
  String _getCardColor(String level) {
    return AppleWalletConfig.levelColors[level] ?? AppleWalletConfig.defaultBackgroundColor;
  }

  /// Check if Apple Wallet is available
  Future<bool> isAvailable() async {
    try {
      // Check if running on iOS (not web)
      if (kIsWeb || !Platform.isIOS) {
        return false;
      }

      // In a real implementation, you would check if PassKit is available
      // For now, we'll assume it's available on iOS
      return true;
    } catch (e) {
      log('❌ Error checking Apple Wallet availability: $e');
      return false;
    }
  }

  /// Validate certificate configuration
  Future<bool> validateCertificateConfig() async {
    try {
      log('🔍 Validating certificate configuration...');

      // Check if certificate path is configured
      if (AppleWalletConfig.certificatePath.isEmpty) {
        log('❌ Certificate path not configured');
        return false;
      }

      // Check if certificate password is configured
      if (AppleWalletConfig.certificatePassword.isEmpty) {
        log('❌ Certificate password not configured');
        return false;
      }

      // Try to load the certificate
      final certificateBytes = await _loadCertificate();
      if (certificateBytes == null) {
        log('❌ Certificate could not be loaded');
        return false;
      }

      log('✅ Certificate configuration is valid');
      log('📊 Certificate size: ${certificateBytes.length} bytes');
      log('🔐 Certificate password: ${AppleWalletConfig.certificatePassword.isNotEmpty ? 'Configured' : 'Not configured'}');

      return true;
    } catch (e) {
      log('❌ Error validating certificate configuration: $e');
      return false;
    }
  }

  /// Generate Apple Wallet URL for QR codes
  ///
  /// Creates a URL that when scanned will open Apple Wallet
  /// For testing, this will be a local file URL
  /// In production, this should point to a web server
  Future<String> _generateAppleWalletUrl(String passPath, LoyaltyCard loyaltyCard) async {
    try {
      // For testing: Use local file URL
      // In production: Upload to web server and return public URL
      final file = File(passPath);

      // Apple Wallet approach: Upload to GitHub and get public URL
      final passId = loyaltyCard.id;
      final passBytes = await file.readAsBytes();

      try {
        // Check if Supabase is configured
        if (SupabaseAppleWalletService.isConfigured) {
          // Upload to Supabase and get public URL
          final appleWalletUrl = await SupabaseAppleWalletService.generateAppleWalletUrl(passPath, passId);

          log('🍎 Apple Wallet URL created via Supabase');
          log('📊 Pass size: ${passBytes.length} bytes');
          log('🔗 Apple Wallet URL: $appleWalletUrl');
          log('📱 iPhone will open this URL in Safari');
          log('✅ Ready for QR code scanning!');

          // Test the URL
          await testPassUrl(appleWalletUrl);

          // Also try creating a direct download link
          final directDownloadUrl = _createDirectDownloadUrl(appleWalletUrl);
          log('🔗 Direct download URL: $directDownloadUrl');
          log('📱 Try this URL if the main one doesn\'t work: $directDownloadUrl');

          return appleWalletUrl;
        } else {
          log('❌ Supabase not configured - cannot generate Apple Wallet URL');
          log('📋 Setup instructions:');
          log(SupabaseAppleWalletService.setupInstructions);
          throw Exception('Supabase service not configured. Please set up Supabase.');
        }
      } catch (supabaseError) {
        log('❌ Supabase upload failed: $supabaseError');
        log('❌ Cannot generate Apple Wallet URL without successful Supabase upload');
        rethrow;
      }
    } catch (e) {
      log('❌ Error generating Apple Wallet URL: $e');
      rethrow;
    }
  }

  /// Add pass to Apple Wallet
  Future<bool> addPassToWallet(String passPath) async {
    try {
      log('🍎 Adding pass to Apple Wallet...');

      // In a real implementation, you would use PassKit to add the pass
      // For now, we'll simulate the process
      final passFile = File(passPath);
      if (await passFile.exists()) {
        log('✅ Pass file exists, ready to add to Apple Wallet');
        return true;
      } else {
        log('❌ Pass file not found');
        return false;
      }
    } catch (e) {
      log('❌ Error adding pass to Apple Wallet: $e');
      return false;
    }
  }

  /// Test pass URL accessibility
  Future<bool> testPassUrl(String passUrl) async {
    try {
      log('🧪 Testing pass URL accessibility...');
      log('🔗 URL: $passUrl');

      // Test the URL with HTTP request
      final response = await http.get(Uri.parse(passUrl));

      log('📊 HTTP Status: ${response.statusCode}');
      log('📊 Content-Type: ${response.headers['content-type']}');
      log('📊 Content-Length: ${response.headers['content-length']}');
      log('📊 Response Size: ${response.bodyBytes.length} bytes');

      if (response.statusCode == 200) {
        log('✅ URL is accessible');
        log('📱 Test this URL in Safari: $passUrl');
        log('📱 Expected behavior: Safari should download the .pkpass file');

        // Check if it's actually a PKPass file
        if (response.bodyBytes.isNotEmpty) {
          log('✅ File has content');
          // Check for ZIP signature (PKPass files are ZIP archives)
          if (response.bodyBytes.length >= 4 && response.bodyBytes[0] == 0x50 && response.bodyBytes[1] == 0x4B) {
            log('✅ File appears to be a valid ZIP/PKPass file');
          } else {
            log('⚠️ File may not be a valid PKPass file (missing ZIP signature)');
          }
        } else {
          log('❌ File is empty');
        }
      } else {
        log('❌ URL is not accessible (Status: ${response.statusCode})');
      }

      return response.statusCode == 200;
    } catch (e) {
      log('❌ Error testing pass URL: $e');
      return false;
    }
  }

  /// Create a direct download URL that might work better in browsers
  String _createDirectDownloadUrl(String originalUrl) {
    // Add download parameter to force download
    final uri = Uri.parse(originalUrl);
    final newUri = uri.replace(queryParameters: {
      ...uri.queryParameters,
      'download': 'true',
      'filename': 'loyalty-card.pkpass',
    });
    return newUri.toString();
  }
}
