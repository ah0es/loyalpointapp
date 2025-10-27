import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Supabase Apple Wallet Service
///
/// Uses Supabase Storage to host .pkpass files
/// Perfect for cross-device QR scanning
class SupabaseAppleWalletService {
  // Supabase configuration
  static const String _supabaseUrl = 'https://dtklhwerhtbzwaviegvq.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR0a2xod2VyaHRiendhdmllZ3ZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE1ODMxODcsImV4cCI6MjA3NzE1OTE4N30.nTA24n7Pny_jTCJTo9P7-4H3f3oG4LpnZbLpcreTT0M';
  static const String _bucketName = 'apple-wallet-passes';

  static String get _baseUrl => '$_supabaseUrl/storage/v1/object/public/$_bucketName';

  /// Upload .pkpass file to Supabase Storage
  ///
  /// Returns the public URL that can be used in QR codes
  static Future<String> uploadPassFile(String localFilePath, String passId) async {
    try {
      log('📤 Uploading .pkpass file to Supabase Storage...');
      log('📁 Local file: $localFilePath');
      log('🆔 Pass ID: $passId');

      // Read the file
      final file = File(localFilePath);
      final fileBytes = await file.readAsBytes();

      log('📊 File size to upload: ${fileBytes.length} bytes');
      log('📊 File exists: ${await file.exists()}');
      log('📊 File readable: ${await file.exists()}');

      // Check file content before upload
      if (fileBytes.isNotEmpty) {
        log('✅ File has content');
        // Check for ZIP signature
        if (fileBytes.length >= 4 && fileBytes[0] == 0x50 && fileBytes[1] == 0x4B) {
          log('✅ File appears to be a valid ZIP/PKPass file');
          log('📊 ZIP signature: ${fileBytes[0].toRadixString(16)} ${fileBytes[1].toRadixString(16)}');
        } else {
          log('❌ File is not a valid PKPass file (missing ZIP signature)');
          log('📊 First 4 bytes: ${fileBytes.take(4).map((b) => b.toRadixString(16)).join(' ')}');
          log('📋 Expected: 50 4B (PK signature)');
        }
      } else {
        log('❌ File is empty - cannot upload');
        throw Exception('PKPass file is empty');
      }

      // Supabase Storage upload URL
      final uploadUrl = '$_supabaseUrl/storage/v1/object/$_bucketName/$passId.pkpass';

      // Make the upload request
      final response = await http.post(
        Uri.parse(uploadUrl),
        headers: {
          'Authorization': 'Bearer $_supabaseAnonKey',
          'Content-Type': 'application/vnd.apple.pkpass',
          'Cache-Control': 'no-cache',
          'Content-Disposition': 'attachment; filename="$passId.pkpass"',
        },
        body: fileBytes,
      );

      log('📊 Upload response status: ${response.statusCode}');
      log('📊 Upload response headers: ${response.headers}');
      log('📊 Upload response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Get the public URL
        final publicUrl = '$_baseUrl/$passId.pkpass';
        log('✅ File uploaded successfully to Supabase Storage');
        log('📊 Uploaded file size: ${fileBytes.length} bytes');
        log('🔗 Public URL: $publicUrl');
        log('📱 This URL should be accessible from Safari/Chrome');

        // Test the public URL immediately
        log('🧪 Testing public URL immediately after upload...');
        try {
          final testResponse = await http.get(Uri.parse(publicUrl));
          log('📊 Test response status: ${testResponse.statusCode}');
          log('📊 Test response content-type: ${testResponse.headers['content-type']}');
          log('📊 Test response size: ${testResponse.bodyBytes.length} bytes');

          if (testResponse.statusCode == 200) {
            log('✅ Public URL is immediately accessible');
          } else {
            log('⚠️ Public URL not immediately accessible (may need time to propagate)');
          }
        } catch (e) {
          log('⚠️ Error testing public URL: $e');
        }

        return publicUrl;
      } else {
        log('❌ Supabase upload failed:');
        log('   Status Code: ${response.statusCode}');
        log('   Response Body: ${response.body}');
        log('   File Size: ${fileBytes.length} bytes');
        log('   Upload URL: $uploadUrl');
        throw Exception('Supabase Storage error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('❌ Error uploading to Supabase Storage: $e');
      rethrow;
    }
  }

  /// Generate Apple Wallet URL for QR code
  ///
  /// This is the URL that should be encoded in the QR code
  static Future<String> generateAppleWalletUrl(String localFilePath, String passId) async {
    try {
      // Upload the .pkpass file to Supabase Storage
      final publicUrl = await uploadPassFile(localFilePath, passId);

      log('🍎 Apple Wallet URL generated via Supabase Storage');
      log('📱 iPhone will open this URL in Safari');
      log('✅ Ready for QR code generation!');

      return publicUrl;
    } catch (e) {
      log('❌ Error generating Apple Wallet URL: $e');
      rethrow;
    }
  }

  /// Check if Supabase is configured
  static bool get isConfigured => _supabaseUrl != 'https://your-project.supabase.co' && _supabaseAnonKey != 'your-anon-key';

  /// Get setup instructions
  static String get setupInstructions => '''
Supabase Apple Wallet Service Setup Required! 🔧

To set up Supabase:

1. Go to https://supabase.com
2. Create a new project (free tier available)
3. Go to Settings → API
4. Copy your Project URL and anon key
5. Update the configuration in this file:
   - _supabaseUrl: Your project URL
   - _supabaseAnonKey: Your anon key

6. Go to Storage → Create bucket
   - Name: apple-wallet-passes
   - Public: Yes (for public URLs)

Your Apple Wallet passes will be available at:
$_baseUrl/

Benefits:
✅ Free tier with generous limits
✅ Public URLs for cross-device scanning
✅ Easy setup and management
✅ No complex authentication
''';
}
