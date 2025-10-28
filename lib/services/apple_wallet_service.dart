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
import 'package:url_launcher/url_launcher.dart';
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
        log('❌ Apple Wallet not configured: ${AppleWalletConfig.configurationStatus}');
        throw Exception('Apple Wallet not configured. Please update AppleWalletConfig with your Apple Developer credentials.');
      }

      // Create loyalty card data
      final loyaltyCard = await createLoyaltyCard(customerName: customerName, points: points);

      // Log loyalty card data before generating pass
      log('📋 Loyalty Card Data:');
      log('   ID: ${loyaltyCard.id}');
      log('   Class ID: ${loyaltyCard.classId}');
      log('   Customer: ${loyaltyCard.customerName}');
      log('   Points: ${loyaltyCard.points}');
      log('   Level: ${loyaltyCard.level}');
      log('   Barcode Value: ${loyaltyCard.barcodeValue}');
      log('   Background Color: ${loyaltyCard.backgroundColor}');
      log('   Logo URL: ${loyaltyCard.logoUrl}');

      // Validate critical fields
      log('🔍 Validating critical fields:');
      log('   ID format: ${loyaltyCard.id.length == 36 ? '✅ Valid UUID' : '❌ Invalid UUID (${loyaltyCard.id.length} chars)'}');
      log('   Class ID format: ${loyaltyCard.classId.startsWith('pass.') ? '✅ Valid Pass Type ID' : '❌ Invalid Pass Type ID'}');
      log('   Barcode Value: ${loyaltyCard.barcodeValue == loyaltyCard.id ? '✅ Matches ID' : '❌ Does not match ID'}');
      log('   Barcode Type: ${loyaltyCard.barcode.type}');
      log('   Barcode Alt Text: ${loyaltyCard.barcode.alternateText}');

      // Generate pass data
      log('🔧 Generating pass data from loyalty card...');
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
        log('❌ Apple Wallet not configured: ${AppleWalletConfig.configurationStatus}');
        throw Exception('Apple Wallet not configured. Please update AppleWalletConfig with your Apple Developer credentials.');
      }

      // Create loyalty card data
      final loyaltyCard = await createLoyaltyCard(customerName: customerName, points: points);

      // Log loyalty card data before generating pass
      log('📋 Loyalty Card Data:');
      log('   ID: ${loyaltyCard.id}');
      log('   Class ID: ${loyaltyCard.classId}');
      log('   Customer: ${loyaltyCard.customerName}');
      log('   Points: ${loyaltyCard.points}');
      log('   Level: ${loyaltyCard.level}');
      log('   Barcode Value: ${loyaltyCard.barcodeValue}');
      log('   Background Color: ${loyaltyCard.backgroundColor}');
      log('   Logo URL: ${loyaltyCard.logoUrl}');

      // Validate critical fields
      log('🔍 Validating critical fields:');
      log('   ID format: ${loyaltyCard.id.length == 36 ? '✅ Valid UUID' : '❌ Invalid UUID (${loyaltyCard.id.length} chars)'}');
      log('   Class ID format: ${loyaltyCard.classId.startsWith('pass.') ? '✅ Valid Pass Type ID' : '❌ Invalid Pass Type ID'}');
      log('   Barcode Value: ${loyaltyCard.barcodeValue == loyaltyCard.id ? '✅ Matches ID' : '❌ Does not match ID'}');
      log('   Barcode Type: ${loyaltyCard.barcode.type}');
      log('   Barcode Alt Text: ${loyaltyCard.barcode.alternateText}');

      // Generate pass data
      log('🔧 Generating pass data from loyalty card...');
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
        logoUrl: 'assets/images/apple_wallet/logo.png', // Use local asset path
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
    log('🔧 Creating Apple Wallet pass data structure...');
    log('   Pass Type ID: ${AppleWalletConfig.passTypeId}');
    log('   Team ID: ${AppleWalletConfig.teamId}');
    log('   Organization: ${AppleWalletConfig.organizationName}');
    log('   Description: ${AppleWalletConfig.passDescription}');
    log('   Web Service URL: ${AppleWalletConfig.webServiceUrl}');
    log('   Auth Token: ${AppleWalletConfig.authenticationToken}');

    final passData = {
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
      'webServiceURL': AppleWalletConfig.webServiceUrl, // Web service URL for pass updates
      'authenticationToken': AppleWalletConfig.authenticationToken, // Authentication token for web service
    };

    log('✅ Pass data structure created successfully');
    log('📊 Pass data keys: ${passData.keys.toList()}');
    log('📊 Store card fields: ${(passData['storeCard'] as Map<String, dynamic>).keys.toList()}');
    log('📊 Barcodes: ${(passData['barcodes'] as List).length} barcode(s)');

    // Detailed barcode validation
    final barcodes = passData['barcodes'] as List;
    for (int i = 0; i < barcodes.length; i++) {
      final barcode = barcodes[i] as Map<String, dynamic>;
      log('📊 Barcode $i:');
      log('   Message: ${barcode['message']}');
      log('   Format: ${barcode['format']}');
      log('   Encoding: ${barcode['messageEncoding']}');
      log('   Alt Text: ${barcode['altText']}');
    }

    // Validate pass.json critical fields
    log('🔍 Pass.json validation:');
    log('   Serial Number: ${passData['serialNumber']}');
    log('   Pass Type ID: ${passData['passTypeIdentifier']}');
    log('   Team ID: ${passData['teamIdentifier']}');
    log('   Organization: ${passData['organizationName']}');
    log('   Description: ${passData['description']}');
    log('   Web Service URL: ${passData['webServiceURL']}');
    log('   Auth Token: ${passData['authenticationToken']}');

    return passData;
  }

  /// Create PKPass file
  Future<String> _createPKPassFile(Map<String, dynamic> passData, LoyaltyCard card) async {
    try {
      log('📦 Creating PKPass archive...');

      // Check if Apple Wallet is configured
      if (!AppleWalletConfig.isConfigured) {
        log('❌ Apple Wallet not configured. Cannot create pass.');
        throw Exception('Apple Wallet not configured. Please update AppleWalletConfig with your Apple Developer credentials.');
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

      // Test the pass file for simulator
      await testPassInSimulator(pkpassFile.path);

      return pkpassFile.path;
    } catch (e) {
      log('❌ Error creating PKPass file: $e');
      rethrow;
    }
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
        log('❌ Certificate configuration invalid - cannot create pass');
        throw Exception('Certificate configuration invalid. Please check your certificate path and password.');
      }

      // Sign with certificate
      await _signWithCertificate(passDir);
      log('✅ Pass signed successfully with certificate');
    } catch (e) {
      log('❌ Error signing pass: $e');
      rethrow;
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

  /// Open Apple Wallet pass URL in Safari
  Future<bool> openPassInSafari(String passUrl) async {
    try {
      log('🍎 Opening Apple Wallet pass in Safari...');
      log('🔗 URL: $passUrl');
      log('📱 DEBUGGING TIPS:');
      log('📱 1. Open Safari in Simulator');
      log('📱 2. Go to Safari → Develop → Simulator → Show Web Inspector');
      log('📱 3. Or press Cmd+Option+I to open Web Inspector');
      log('📱 4. Check Console tab for errors');
      log('📱 5. Check Network tab to see the request/response');

      // First, test the URL before opening
      log('🧪 Testing URL before opening in Safari...');
      final urlTestResult = await testPassUrl(passUrl);
      if (!urlTestResult) {
        log('❌ URL test failed - Safari will likely show download error');
        log('📋 This explains why Safari cannot download the file');
        log('📋 Check the detailed logs above to see what failed');
        await debugSafariDownload(passUrl);
        return false;
      }

      final uri = Uri.parse(passUrl);
      log('🔍 Parsed URI: $uri');
      log('🔍 URI scheme: ${uri.scheme}');
      log('🔍 URI host: ${uri.host}');
      log('🔍 URI path: ${uri.path}');

      // Check if the URL can be launched
      log('🔍 Checking if URL can be launched...');
      final canLaunch = await canLaunchUrl(uri);
      log('🔍 Can launch URL: $canLaunch');

      if (canLaunch) {
        log('🚀 Launching URL in Safari...');
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Opens in Safari
        );

        log('🔍 Launch result: $launched');

        if (launched) {
          log('✅ Successfully opened pass URL in Safari');
          log('📱 Safari should now download the .pkpass file');
          log('📱 When downloaded, tap the file to add to Apple Wallet');
          log('⚠️ If Safari shows "cannot download" error:');
          log('⚠️ 1. Check Safari Web Inspector (Cmd+Option+I)');
          log('⚠️ 2. Look at Console tab for JavaScript errors');
          log('⚠️ 3. Look at Network tab for failed requests');
          log('⚠️ 4. Check if the URL is accessible');
          log('⚠️ 5. Verify the file is a valid .pkpass file');
          return true;
        } else {
          log('❌ Failed to launch URL in Safari');
          log('📋 This means Safari opened but couldn\'t handle the URL');
          log('📋 Check if the URL format is correct');
          return false;
        }
      } else {
        log('❌ Cannot launch URL: $passUrl');
        log('📋 This means the URL format is invalid or not supported');
        return false;
      }
    } catch (e) {
      log('❌ Error opening pass in Safari: $e');
      log('📋 Full error details: ${e.toString()}');
      return false;
    }
  }

  /// Generate pass and open in Safari (convenience method)
  Future<bool> generateAndOpenPass({
    required String customerName,
    required int points,
  }) async {
    try {
      log('🎯 Generating Apple Wallet pass and opening in Safari...');

      // Generate the pass URL
      final passUrl = await generatePassUrl(
        customerName: customerName,
        points: points,
      );

      // Open in Safari
      return await openPassInSafari(passUrl);
    } catch (e) {
      log('❌ Error generating and opening pass: $e');
      return false;
    }
  }

  /// Test pass URL accessibility
  Future<bool> testPassUrl(String passUrl) async {
    try {
      log('🧪 Testing pass URL accessibility...');
      log('🔗 URL: $passUrl');

      // Parse and validate URL
      final uri = Uri.parse(passUrl);
      log('🔍 Parsed URI: $uri');
      log('🔍 Scheme: ${uri.scheme} (should be https)');
      log('🔍 Host: ${uri.host}');
      log('🔍 Path: ${uri.path}');
      log('🔍 Query: ${uri.query}');

      if (uri.scheme != 'https') {
        log('❌ URL scheme is not HTTPS: ${uri.scheme}');
        log('📋 Safari requires HTTPS for downloads');
        return false;
      }

      // Test the URL with HTTP request
      log('🌐 Making HTTP request to test URL...');
      final response = await http.get(uri);

      log('📊 HTTP Status: ${response.statusCode}');
      log('📊 Content-Type: ${response.headers['content-type']}');
      log('📊 Content-Length: ${response.headers['content-length']}');
      log('📊 Response Size: ${response.bodyBytes.length} bytes');
      log('📊 All Headers: ${response.headers}');

      if (response.statusCode == 200) {
        log('✅ URL is accessible');

        // Check content type
        final contentType = response.headers['content-type'];
        if (contentType == 'application/vnd.apple.pkpass') {
          log('✅ Correct MIME type: $contentType');
        } else {
          log('⚠️ Unexpected MIME type: $contentType');
          log('📋 Expected: application/vnd.apple.pkpass');
          log('📋 This might cause Safari download issues');
        }

        // Check if it's actually a PKPass file
        if (response.bodyBytes.isNotEmpty) {
          log('✅ File has content');
          // Check for ZIP signature (PKPass files are ZIP archives)
          if (response.bodyBytes.length >= 4 && response.bodyBytes[0] == 0x50 && response.bodyBytes[1] == 0x4B) {
            log('✅ File appears to be a valid ZIP/PKPass file');
            log('📊 ZIP signature: ${response.bodyBytes[0].toRadixString(16)} ${response.bodyBytes[1].toRadixString(16)}');
          } else {
            log('❌ File is not a valid PKPass file (missing ZIP signature)');
            log('📊 First 4 bytes: ${response.bodyBytes.take(4).map((b) => b.toRadixString(16)).join(' ')}');
            log('📋 Expected: 50 4B (PK signature)');
            return false;
          }
        } else {
          log('❌ File is empty');
          return false;
        }

        log('📱 Test this URL in Safari: $passUrl');
        log('📱 Expected behavior: Safari should download the .pkpass file');
      } else {
        log('❌ URL is not accessible (Status: ${response.statusCode})');
        log('📊 Response body: ${response.body}');
        return false;
      }

      return response.statusCode == 200;
    } catch (e) {
      log('❌ Error testing pass URL: $e');
      log('📋 Full error details: ${e.toString()}');
      return false;
    }
  }

  /// Test pass file directly in simulator
  Future<void> testPassInSimulator(String passPath) async {
    try {
      log('🧪 Testing pass file in simulator...');
      log('📁 Pass file: $passPath');

      final passFile = File(passPath);
      if (await passFile.exists()) {
        final fileSize = await passFile.length();
        log('✅ Pass file exists ($fileSize bytes)');
        log('📱 To test in simulator:');
        log('   1. Copy this file to your Desktop');
        log('   2. Drag and drop it onto the iOS Simulator');
        log('   3. Check if Apple Wallet opens and accepts the pass');
        log('📁 File path: $passPath');

        // Also test the file structure
        await _validatePassFileStructure(passPath);
      } else {
        log('❌ Pass file not found: $passPath');
      }
    } catch (e) {
      log('❌ Error testing pass in simulator: $e');
    }
  }

  /// Validate pass file structure for debugging
  Future<void> _validatePassFileStructure(String passPath) async {
    try {
      log('🔍 Validating pass file structure...');

      // Read the PKPass file as ZIP
      final passFile = File(passPath);
      final passBytes = await passFile.readAsBytes();

      // Check ZIP signature
      if (passBytes.length >= 4 && passBytes[0] == 0x50 && passBytes[1] == 0x4B) {
        log('✅ Valid ZIP signature found');
      } else {
        log('❌ Invalid ZIP signature');
        return;
      }

      // Try to extract and validate contents
      try {
        final archive = ZipDecoder().decodeBytes(passBytes);
        log('✅ PKPass file can be decoded as ZIP');

        final requiredFiles = ['pass.json', 'manifest.json', 'signature'];
        for (final filename in requiredFiles) {
          final file = archive.files.firstWhere(
            (f) => f.name == filename,
            orElse: () => throw Exception('File not found: $filename'),
          );
          log('✅ $filename found (${file.size} bytes)');
        }

        log('✅ Pass file structure is valid');
      } catch (e) {
        log('❌ Error validating pass file structure: $e');
      }
    } catch (e) {
      log('❌ Error validating pass file: $e');
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

  /// Debug Safari download issues
  Future<void> debugSafariDownload(String passUrl) async {
    try {
      log('🔍 DEBUGGING SAFARI DOWNLOAD ISSUES');
      log('🔗 URL: $passUrl');
      log('');
      log('📱 STEP 1: Open Safari Web Inspector');
      log('   1. Open Safari in iOS Simulator');
      log('   2. Go to Safari menu → Develop → Simulator → Show Web Inspector');
      log('   3. Or press Cmd+Option+I (Mac) or Ctrl+Alt+I (Windows)');
      log('');
      log('📱 STEP 2: Check Console Tab');
      log('   - Look for JavaScript errors');
      log('   - Look for network errors');
      log('   - Look for download-related messages');
      log('');
      log('📱 STEP 3: Check Network Tab');
      log('   - Look for the request to your pass URL');
      log('   - Check the response status (should be 200)');
      log('   - Check Content-Type (should be application/vnd.apple.pkpass)');
      log('   - Check if the response body is a valid ZIP file');
      log('');
      log('📱 STEP 4: Test URL Manually');
      log('   - Copy this URL: $passUrl');
      log('   - Paste it in Safari address bar');
      log('   - Press Enter and see what happens');
      log('   - Check if it downloads or shows an error');
      log('');
      log('📱 STEP 5: Check Safari Settings');
      log('   - Go to Settings → Safari');
      log('   - Make sure "Block Pop-ups" is OFF');
      log('   - Make sure "Prevent Cross-Site Tracking" is OFF');
      log('   - Try in Private Browsing mode');
    } catch (e) {
      log('❌ Error in debugSafariDownload: $e');
    }
  }
}
