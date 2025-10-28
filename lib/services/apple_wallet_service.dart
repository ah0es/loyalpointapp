import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import '../models/loyalty_card.dart';
import '../config/apple_wallet_config.dart';
import '../pass_generator.dart';
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
    if (!AppleWalletConfig.isConfigured) {
      throw Exception('Apple Wallet not configured.');
    }

    final loyaltyCard = await createLoyaltyCard(customerName: customerName, points: points);

    final pkpassBytes = await PassGenerator.generatePass(
      eventName: loyaltyCard.customerName,
      eventDate: DateTime.now().toIso8601String(),
      barcodeMessage: loyaltyCard.id,
    );

    // On web, avoid filesystem; upload bytes directly
    if (kIsWeb) {
      if (!SupabaseAppleWalletService.isConfigured) {
        throw Exception('Supabase service not configured.');
      }
      return await SupabaseAppleWalletService.generateAppleWalletUrlFromBytes(pkpassBytes, loyaltyCard.id);
    }

    final passPath = await _writePkpassToTemp(pkpassBytes, loyaltyCard.id);
    return await _generateAppleWalletUrl(passPath, loyaltyCard);
  }

  // Legacy generatePass method removed; use generatePassUrl for QR

  /// Create loyalty card data for Apple Wallet
  Future<LoyaltyCard> createLoyaltyCard({required String customerName, required int points}) async {
    final userId = _uuid.v4();
    final level = _determineLevel(points);

    return LoyaltyCard(
      id: userId,
      classId: AppleWalletConfig.passTypeId,
      state: 'ACTIVE',
      customerName: customerName,
      points: points,
      level: level,
      barcodeValue: userId,
      cardTitle: 'Loyalty Card',
      header: customerName,
      backgroundColor: _getCardColor(level),
      logoUrl: 'assets/images/apple_wallet/logo.png',
      textModules: [
        TextModule(id: 'points', header: 'POINTS', body: points.toString()),
        TextModule(id: 'level', header: 'LEVEL', body: level),
      ],
      barcode: Barcode(type: 'QR_CODE', value: userId, alternateText: userId),
    );
  }

  // Pass generation now handled by PassGenerator; no local pass.json building needed

  /// Write .pkpass bytes to a temporary file and return its path
  Future<String> _writePkpassToTemp(Uint8List pkpassBytes, String passId) async {
    final tempDir = await getTemporaryDirectory();
    final pkpassFile = File('${tempDir.path}/loyalty_$passId.pkpass');
    await pkpassFile.writeAsBytes(pkpassBytes);
    return pkpassFile.path;
  }

  // Image asset handling is now encapsulated by PassGenerator

  // Legacy asset loader removed

  // Placeholder image generation removed

  // Manifest creation handled by PassGenerator

  // Certificate signing removed (handled by backend signer in PassGenerator flow)

  // Local certificate signing implementation removed

  // Certificate loading removed

  // PKCS#7 creation removed

  // Local pass structure validation removed

  // Field validation now relies on PassKit processing and backend signer

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

  // Certificate validation no longer required in PassGenerator flow

  Future<String> _generateAppleWalletUrl(String passPath, LoyaltyCard loyaltyCard) async {
    final passId = loyaltyCard.id;
    if (!SupabaseAppleWalletService.isConfigured) {
      throw Exception('Supabase service not configured.');
    }
    final url = await SupabaseAppleWalletService.generateAppleWalletUrl(passPath, passId);
    // Ensure force-download variant for better iOS compatibility
    final uri = Uri.parse(url);
    final withDownload = uri.replace(queryParameters: {
      ...uri.queryParameters,
      'download': 'loyalty-card.pkpass',
    }).toString();
    return withDownload;
  }

  // Opening/adding/debug utilities removed for QR-only flow
}
