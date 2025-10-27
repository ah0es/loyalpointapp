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
      log('🎯 Generating wallet pass for platform: $platform');

      if (_isIOS()) {
        // Try Apple Wallet first
        final appleResult = await _generateAppleWalletPass(customerName: customerName, points: points);

        // If Apple Wallet fails, fall back to Google Wallet
        if (!appleResult.success) {
          log('⚠️ Apple Wallet failed, falling back to Google Wallet...');
          return await _generateGoogleWalletPass(customerName: customerName, points: points);
        }

        return appleResult;
      } else {
        return await _generateGoogleWalletPass(customerName: customerName, points: points);
      }
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
      log('🍎 Generating Apple Wallet pass...');

      // Check if Apple Wallet is available
      final isAvailable = await _appleWalletService.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple Wallet is not available on this device');
      }

      // Generate pass URL for QR code
      final passUrl = await _appleWalletService.generatePassUrl(
        customerName: customerName,
        points: points,
      );

      return WalletPassResult(
        type: WalletType.apple,
        data: passUrl,
        success: true,
        message: 'Apple Wallet pass URL generated successfully',
      );
    } catch (e) {
      log('❌ Error generating Apple Wallet pass: $e');
      return WalletPassResult(
        type: WalletType.apple,
        data: null,
        success: false,
        message: 'Failed to generate Apple Wallet pass: $e',
      );
    }
  }

  /// Generate Google Wallet pass
  Future<WalletPassResult> _generateGoogleWalletPass({
    required String customerName,
    required int points,
  }) async {
    try {
      log('🔵 Generating Google Wallet pass...');

      // Generate Save URL
      final saveUrl = await _googleWalletService.generateSaveUrl(
        customerName: customerName,
        points: points,
      );

      return WalletPassResult(
        type: WalletType.google,
        data: saveUrl,
        success: true,
        message: 'Google Wallet Save URL generated successfully',
      );
    } catch (e) {
      log('❌ Error generating Google Wallet pass: $e');
      return WalletPassResult(
        type: WalletType.google,
        data: null,
        success: false,
        message: 'Failed to generate Google Wallet pass: $e',
      );
    }
  }

  /// Add pass to wallet
  Future<bool> addPassToWallet(WalletPassResult result) async {
    try {
      if (!result.success || result.data == null) {
        log('❌ Cannot add pass to wallet: ${result.message}');
        return false;
      }

      switch (result.type) {
        case WalletType.apple:
          // For Apple Wallet, we don't need to add directly - the URL is for QR scanning
          log('🍎 Apple Wallet URL generated for QR scanning: ${result.data}');
          return true;
        case WalletType.google:
          return await _googleWalletService.launchSaveUrl(result.data!);
      }
    } catch (e) {
      log('❌ Error adding pass to wallet: $e');
      return false;
    }
  }

  /// Check wallet availability for current platform
  Future<WalletAvailability> checkWalletAvailability() async {
    try {
      if (_isIOS()) {
        final isAvailable = await _appleWalletService.isAvailable();
        return WalletAvailability(
          type: WalletType.apple,
          isAvailable: isAvailable,
          message: isAvailable ? 'Apple Wallet is available' : 'Apple Wallet is not available on this device',
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
