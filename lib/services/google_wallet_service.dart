import 'dart:developer';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/wallet_config.dart';
import '../models/loyalty_card.dart';
import '../models/service_account.dart';
import 'jwt_generator.dart';
import 'class_creator.dart';

/// Google Wallet Service
///
/// Main service for generating loyalty cards and creating Google Wallet Save URLs
/// Handles card creation, JWT generation, and QR code data preparation
class GoogleWalletService {
  final ServiceAccount _serviceAccount;
  final JWTGenerator _jwtGenerator;
  final ClassCreator _classCreator;
  final Uuid _uuid = const Uuid();

  GoogleWalletService()
    : _serviceAccount = ServiceAccount.fromConfig(),
      _jwtGenerator = JWTGenerator(ServiceAccount.fromConfig()),
      _classCreator = ClassCreator();

  /// Generate Save to Wallet URL
  ///
  /// Creates a loyalty card, wraps it in a JWT, and returns the Google Wallet Save URL
  /// This URL can be used in QR codes or direct links to add cards to Google Wallet
  Future<String> generateSaveUrl({required String customerName, required int points}) async {
    try {
      log('🎯 Generating Save to Wallet URL...');
      log('👤 Customer: $customerName');
      log('⭐ Points: $points');

      // Skip class creation since it already exists in Google Wallet Console
      log('✅ Using existing loyalty card class from Google Wallet Console');
      log('🔍 Class ID: ${WalletConfig.fullClassId}');
      log('🔍 Issuer ID: ${WalletConfig.issuerId}');
      log('🔍 Service Account: ${WalletConfig.serviceAccountEmail}');

      // Create loyalty card
      final loyaltyCard = await createCard(customerName: customerName, points: points);

      log('💳 Loyalty card created: ${loyaltyCard.id}');
      log('🔍 Using class ID: ${loyaltyCard.classId}');

      // Convert to Google Wallet object format
      final walletObject = loyaltyCard.toGoogleWalletObject();
      log('📱 Google Wallet object created');
      log('🔍 Object type: Loyalty (matching class type)');

      // Generate JWT with the loyalty card
      final jwt = await _jwtGenerator.generateSaveToWalletJWT(walletObject);
      log('🔐 JWT generated (length: ${jwt.length})');

      // Create the Save to Wallet URL
      final saveUrl = '${WalletConfig.saveToWalletBaseUrl}/$jwt';
      log('🔗 Save URL created: ${saveUrl.substring(0, 50)}...');

      return saveUrl;
    } catch (e) {
      log('❌ Error generating Save URL: $e');
      rethrow;
    }
  }

  /// Create a loyalty card with all required fields
  ///
  /// Generates a unique user ID, determines loyalty level based on points,
  /// and creates a complete LoyaltyCard object ready for Google Wallet
  Future<LoyaltyCard> createCard({required String customerName, required int points}) async {
    try {
      log('💳 Creating loyalty card...');

      // Generate unique user ID
      final userId = _uuid.v4();
      final objectId = _serviceAccount.getObjectId(userId);

      // Determine loyalty level based on points
      final level = _determineLevel(points);
      log('🏆 Level determined: $level');

      // Create text modules for the card
      final textModules = [
        TextModule(id: 'points', header: 'POINTS', body: points.toString()),
        TextModule(id: 'level', header: 'LEVEL', body: level),
      ];

      // Create barcode
      final barcode = Barcode(type: 'QR_CODE', value: userId, alternateText: userId);

      // Create the loyalty card
      final loyaltyCard = LoyaltyCard(
        id: objectId,
        classId: _serviceAccount.fullClassId,
        state: 'ACTIVE',
        customerName: customerName,
        points: points,
        level: level,
        barcodeValue: userId,
        cardTitle: 'Loyalty Card',
        header: customerName,
        backgroundColor: _getCardColor(level),
        logoUrl: WalletConfig.logoUrl,
        textModules: textModules,
        barcode: barcode,
      );

      log('✅ Loyalty card created successfully');
      return loyaltyCard;
    } catch (e) {
      log('❌ Error creating loyalty card: $e');
      rethrow;
    }
  }

  /// Determine loyalty level based on points
  ///
  /// Bronze: 0-99 points
  /// Silver: 100-499 points
  /// Gold: 500-999 points
  /// Platinum: 1000+ points
  String _determineLevel(int points) {
    if (points >= WalletConfig.levelThresholds['Platinum']!) {
      return 'Platinum';
    } else if (points >= WalletConfig.levelThresholds['Gold']!) {
      return 'Gold';
    } else if (points >= WalletConfig.levelThresholds['Silver']!) {
      return 'Silver';
    } else {
      return 'Bronze';
    }
  }

  /// Launch Save to Wallet URL
  ///
  /// Opens the Save to Wallet URL in the default browser
  /// This allows users to add the loyalty card directly to their Google Wallet
  Future<bool> launchSaveUrl(String saveUrl) async {
    try {
      log('🚀 Launching Save to Wallet URL...');

      final uri = Uri.parse(saveUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (launched) {
        log('✅ Save URL launched successfully');
      } else {
        log('❌ Failed to launch Save URL');
      }

      return launched;
    } catch (e) {
      log('❌ Error launching Save URL: $e');
      return false;
    }
  }

  /// Validate customer input
  ///
  /// Ensures customer name is not empty and points is a valid number
  String? validateInput(String customerName, String pointsText) {
    if (customerName.trim().isEmpty) {
      return 'Customer name is required';
    }

    if (pointsText.trim().isEmpty) {
      return 'Points is required';
    }

    final points = int.tryParse(pointsText.trim());
    if (points == null) {
      return 'Points must be a valid number';
    }

    if (points < 0) {
      return 'Points cannot be negative';
    }

    return null; // No validation errors
  }

  /// Get card preview data
  ///
  /// Returns formatted data for displaying card information
  Map<String, dynamic> getCardPreview({required String customerName, required int points}) {
    final level = _determineLevel(points);

    return {'customerName': customerName, 'points': points, 'level': level, 'backgroundColor': _getCardColor(level), 'logoUrl': WalletConfig.logoUrl};
  }

  /// Get card color based on loyalty level
  String _getCardColor(String level) {
    switch (level) {
      case 'Bronze':
        return '#CD7F32'; // Bronze color
      case 'Silver':
        return '#C0C0C0'; // Silver color
      case 'Gold':
        return '#FFD700'; // Gold color
      case 'Platinum':
        return '#E5E4E2'; // Platinum color
      default:
        return WalletConfig.cardBackgroundColor;
    }
  }
}
