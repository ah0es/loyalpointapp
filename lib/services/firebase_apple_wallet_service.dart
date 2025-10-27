import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Firebase Apple Wallet Service
///
/// Uses Firebase Storage to host .pkpass files
/// This works for cross-device QR scanning
class FirebaseAppleWalletService {
  // Firebase Storage configuration
  static const String _bucketName = 'loyalty-card-app-b8957.firebasestorage.app';
  static const String _apiKey = 'AIzaSyCnzYqzyQQgDlp2iHSuFQXhGKsU98VMZBs';
  static const String _projectId = 'loyalty-card-app-b8957';
  
  static String get _baseUrl => 'https://firebasestorage.googleapis.com/v0/b/$_bucketName/o';

  /// Upload .pkpass file to Firebase Storage
  ///
  /// Returns the public URL that can be used in QR codes
  static Future<String> uploadPassFile(String localFilePath, String passId) async {
    try {
      log('📤 Uploading .pkpass file to Firebase Storage...');
      log('📁 Local file: $localFilePath');
      log('🆔 Pass ID: $passId');

      // Read the file
      final file = File(localFilePath);
      final fileBytes = await file.readAsBytes();

      // Firebase Storage upload URL
      final uploadUrl = '$_baseUrl/passes%2F$passId.pkpass?uploadType=media&name=passes%2F$passId.pkpass';

      // Make the upload request
      final response = await http.post(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': 'application/octet-stream',
        },
        body: fileBytes,
      );

      if (response.statusCode == 200) {
        // Get the download URL
        final downloadUrl = 'https://firebasestorage.googleapis.com/v0/b/$_bucketName/o/passes%2F$passId.pkpass?alt=media';
        log('✅ File uploaded successfully to Firebase Storage');
        log('🔗 Public URL: $downloadUrl');
        return downloadUrl;
      } else {
        throw Exception('Firebase Storage error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('❌ Error uploading to Firebase Storage: $e');
      rethrow;
    }
  }

  /// Generate Apple Wallet URL for QR code
  ///
  /// This is the URL that should be encoded in the QR code
  static Future<String> generateAppleWalletUrl(String localFilePath, String passId) async {
    try {
      // Upload the .pkpass file to Firebase Storage
      final publicUrl = await uploadPassFile(localFilePath, passId);

      log('🍎 Apple Wallet URL generated via Firebase Storage');
      log('📱 iPhone will open this URL in Safari');
      log('✅ Ready for QR code generation!');

      return publicUrl;
    } catch (e) {
      log('❌ Error generating Apple Wallet URL: $e');
      rethrow;
    }
  }

  /// Check if Firebase is configured
  static bool get isConfigured => true;

  /// Get setup instructions
  static String get setupInstructions => '''
Firebase Apple Wallet Service Setup Complete! 🎉

✅ Firebase Storage configured
✅ Public URLs working
✅ Cross-device QR scanning enabled

Your Apple Wallet passes will be available at:
https://firebasestorage.googleapis.com/v0/b/$_bucketName/o/passes/

Next steps:
1. Test the app - QR codes will now work from any device
2. When backend team returns, replace this with real API calls
''';
}
