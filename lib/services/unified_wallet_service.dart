import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'google_wallet_service.dart';
import 'apple_wallet_service.dart';

/// Unified Wallet Service
///
/// Handles both Google Wallet and Apple Wallet integration
/// Automatically detects platform and provides appropriate wallet functionality
class UnifiedWalletService {
  final GoogleWalletService _googleWalletService = GoogleWalletService();
  final AppleWalletService _appleWalletService = AppleWalletService();

  /// Safely check if running on iOS
  bool _isIOS() {
    try {
      return !kIsWeb && Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  /// Get platform name for logging
  String _getPlatformName() {
    if (kIsWeb) return 'Web';
    try {
      return Platform.operatingSystem;
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Generate wallet pass for the current platform
  ///
  /// Automatically detects platform and generates appropriate pass:
  /// - iOS: Apple Wallet PKPass file (with Google Wallet fallback)
  /// - Android/Web/Other: Google Wallet Save URL
  Future<WalletPassResult> generateWalletPass({
    required String customerName,
    required int points,
  }) async {
    try {
      final platform = _getPlatformName();
      log('🎯 Generating wallet pass (Apple-first) for platform: $platform');
      // Always generate Apple Wallet URL (QR-based, works cross-device)
      return await _generateAppleWalletPass(customerName: customerName, points: points);
    } catch (e) {
      log('❌ Error generating wallet pass: $e');
      rethrow;
    }
  }

  /// Generate Apple Wallet pass
  Future<WalletPassResult> _generateAppleWalletPass({
    required String customerName,
    required int points,
  }) async {
    try {
      log('🍎 Generating Apple Wallet pass URL...');
      // Generate pass URL for QR code (no availability check, QR works cross-device)
      final passUrl = await _appleWalletService.generatePassUrl(
        customerName: customerName,
        points: points,
      );

      // Ensure download parameter for iOS Safari
      final uri = Uri.parse(passUrl);
      final normalizedUrl = uri.queryParameters.containsKey('download')
          ? passUrl
          : uri.replace(queryParameters: {
              ...uri.queryParameters,
              'download': 'loyalty-card.pkpass',
            }).toString();

      return WalletPassResult(
        type: WalletType.apple,
        data: normalizedUrl,
        success: true,
        message: 'Apple Wallet pass URL generated successfully',
      );
    } catch (e) {
      log('❌ Error generating Apple Wallet pass: $e');

      // Even when it fails, provide a fallback URL for QR display
      final fallbackUrl = 'https://ah0es.github.io/loyalpointapp/passes/error-${DateTime.now().millisecondsSinceEpoch}.pkpass';

      return WalletPassResult(
        type: WalletType.apple,
        data: fallbackUrl,
        success: false,
        message: 'Apple Wallet failed: $e',
      );
    }
  }

  // Google Wallet generation disabled for Apple-only testing

  /// Add pass to wallet
  Future<bool> addPassToWallet(WalletPassResult result) async {
    try {
      log('🎯 addPassToWallet called');
      log('🎯 Result success: ${result.success}');
      log('🎯 Result type: ${result.type}');
      log('🎯 Result data: ${result.data}');
      log('🎯 Result message: ${result.message}');

      if (!result.success || result.data == null) {
        log('❌ Cannot add pass to wallet: ${result.message}');
        return false;
      }

      switch (result.type) {
        case WalletType.apple:
          // For Apple Wallet, we now only generate a URL for QR; nothing to open here
          return true;
        case WalletType.google:
          log('🤖 Opening Google Wallet pass: ${result.data}');
          return await _googleWalletService.launchSaveUrl(result.data!);
      }
    } catch (e) {
      log('❌ Error adding pass to wallet: $e');
      log('❌ Full error details: ${e.toString()}');
      return false;
    }
  }

  /// Open Apple Wallet pass in Safari (convenience method)
  Future<bool> openAppleWalletPass({
    required String customerName,
    required int points,
  }) async {
    try {
      log('🍎 Generating Apple Wallet pass URL (no auto-open)...');
      await _appleWalletService.generatePassUrl(
        customerName: customerName,
        points: points,
      );
      return true;
    } catch (e) {
      log('❌ Error opening Apple Wallet pass: $e');
      return false;
    }
  }

  /// Check wallet availability for current platform
  Future<WalletAvailability> checkWalletAvailability() async {
    try {
      if (_isIOS()) {
        return WalletAvailability(
          type: WalletType.apple,
          isAvailable: true,
          message: 'Apple Wallet is available',
        );
      } else {
        // For Google Wallet, we assume it's available if we can generate URLs
        return WalletAvailability(
          type: WalletType.google,
          isAvailable: true,
          message: 'Google Wallet is available',
        );
      }
    } catch (e) {
      log('❌ Error checking wallet availability: $e');
      return WalletAvailability(
        type: _isIOS() ? WalletType.apple : WalletType.google,
        isAvailable: false,
        message: 'Error checking wallet availability: $e',
      );
    }
  }

  /// Get supported wallet types for current platform
  List<WalletType> getSupportedWallets() {
    if (_isIOS()) {
      return [WalletType.apple, WalletType.google];
    } else {
      return [WalletType.google];
    }
  }

  /// Validate input for wallet pass generation
  String? validateInput(String customerName, String pointsText) {
    return _googleWalletService.validateInput(customerName, pointsText);
  }

  /// Get card preview data
  Map<String, dynamic> getCardPreview({required String customerName, required int points}) {
    return _googleWalletService.getCardPreview(customerName: customerName, points: points);
  }

  /// For Windows testing: generate Apple Wallet pass URL directly (ignores platform)
  Future<String> generateApplePassUrlForTesting({
    required String customerName,
    required int points,
  }) async {
    return _appleWalletService.generatePassUrl(customerName: customerName, points: points);
  }
}

/// Wallet types supported by the app
enum WalletType {
  google,
  apple,
}

/// Result of wallet pass generation
class WalletPassResult {
  final WalletType type;
  final String? data; // Save URL for Google Wallet, file path for Apple Wallet
  final bool success;
  final String message;

  WalletPassResult({
    required this.type,
    required this.data,
    required this.success,
    required this.message,
  });
}

/// Wallet availability information
class WalletAvailability {
  final WalletType type;
  final bool isAvailable;
  final String message;

  WalletAvailability({
    required this.type,
    required this.isAvailable,
    required this.message,
  });
}
