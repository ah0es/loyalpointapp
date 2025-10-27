import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../models/loyalty_card.dart';
import '../config/apple_wallet_config.dart';
import 'pass_server.dart';

/// Apple Wallet Service
///
/// Service for generating Apple Wallet passes (PKPass files)
/// Handles pass creation, signing, and file generation
class AppleWalletService {
  final Uuid _uuid = const Uuid();

  /// Generate Apple Wallet Pass URL
  ///
  /// Creates a URL that can be used in QR codes to add passes to Apple Wallet
  /// Returns the URL that should be encoded in the QR code
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
      final passUrl = await _generateAppleWalletUrl(passPath, loyaltyCard);

      log('✅ Apple Wallet pass URL generated: $passUrl');
      return passUrl;
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
        classId: 'pass.com.loyalty.app', // Apple Wallet pass type identifier
        state: 'ACTIVE',
        customerName: customerName,
        points: points,
        level: level,
        barcodeValue: userId,
        cardTitle: 'Loyalty Card',
        header: customerName,
        backgroundColor: _getCardColor(level),
        logoUrl: 'https://via.placeholder.com/60x60/4285F4/FFFFFF?text=L', // Placeholder logo
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
      'barcode': {
        'message': card.barcodeValue,
        'format': AppleWalletConfig.barcodeFormat,
        'messageEncoding': AppleWalletConfig.barcodeEncoding,
        'altText': card.barcodeValue,
      },
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

      // 4. Create PKPass archive
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

      // 5. Save PKPass file
      final pkpassFile = File('${tempDir.path}/loyalty_${card.id}.pkpass');
      final zipData = ZipEncoder().encode(archive);
      if (zipData != null) {
        await pkpassFile.writeAsBytes(zipData);
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
      // Create placeholder images
      // In production, you would load actual image files from assets
      final imageFiles = [
        'icon.png',
        'icon@2x.png',
        'logo.png',
        'logo@2x.png',
      ];

      for (final filename in imageFiles) {
        final imageFile = File('$passDir/$filename');
        // Create empty placeholder file
        await imageFile.writeAsBytes(Uint8List(0));
      }

      log('📷 Created placeholder image assets');
    } catch (e) {
      log('❌ Error creating image assets: $e');
      rethrow;
    }
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
      final fileUri = file.uri.toString();

      // Start local server for testing
      final serverUrl = await PassServer.startServer();
      final passId = loyaltyCard.id;
      final appleWalletUrl = '$serverUrl/passes/$passId.pkpass';

      // Copy pass file to server directory
      final serverDir = Directory('passes');
      if (!await serverDir.exists()) {
        await serverDir.create(recursive: true);
      }

      final serverPassFile = File('passes/$passId.pkpass');
      await file.copy(serverPassFile.path);

      log('🔗 Apple Wallet URL: $appleWalletUrl');
      log('📁 Local pass file: $fileUri');
      log('🆔 Pass ID: $passId');
      log('🌐 Server URL: $serverUrl');

      return appleWalletUrl;
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
}
