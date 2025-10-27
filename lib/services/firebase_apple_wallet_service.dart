import 'dart:io';
import 'dart:developer';
import 'package:firebase_storage/firebase_storage.dart';

/// Firebase Apple Wallet Service
///
/// Handles uploading .pkpass files to Firebase Storage
/// and generating public URLs for Apple Wallet QR codes
class FirebaseAppleWalletService {
  static FirebaseStorage? _storage;
  static String? _baseUrl;

  /// Initialize Firebase Storage
  static Future<void> initialize() async {
    try {
      // Firebase is already initialized in main.dart
      _storage = FirebaseStorage.instance;
      _baseUrl = 'https://storage.googleapis.com/${_storage!.bucket}/passes';
      log('🔥 Firebase Storage initialized');
      log('🌐 Base URL: $_baseUrl');
    } catch (e) {
      log('❌ Error initializing Firebase Storage: $e');
      rethrow;
    }
  }

  /// Upload .pkpass file to Firebase Storage
  ///
  /// Returns the public URL that can be used in QR codes
  static Future<String> uploadPassFile(String localFilePath, String passId) async {
    try {
      if (_storage == null) {
        await initialize();
      }

      log('📤 Uploading .pkpass file to Firebase Storage...');
      log('📁 Local file: $localFilePath');
      log('🆔 Pass ID: $passId');

      // Create reference to Firebase Storage
      final ref = _storage!.ref().child('passes/$passId.pkpass');

      // Upload the file
      final uploadTask = await ref.putFile(File(localFilePath));

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      log('✅ File uploaded successfully');
      log('🔗 Public URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      log('❌ Error uploading to Firebase: $e');
      rethrow;
    }
  }

  /// Generate Apple Wallet URL for QR code
  ///
  /// This is the URL that should be encoded in the QR code
  static Future<String> generateAppleWalletUrl(String localFilePath, String passId) async {
    try {
      // Upload the .pkpass file to Firebase
      final publicUrl = await uploadPassFile(localFilePath, passId);

      log('🍎 Apple Wallet URL generated: $publicUrl');
      log('📱 iPhone will open this URL in Safari');
      log('✅ Ready for QR code generation!');

      return publicUrl;
    } catch (e) {
      log('❌ Error generating Apple Wallet URL: $e');
      rethrow;
    }
  }

  /// Delete pass file from Firebase Storage
  static Future<void> deletePassFile(String passId) async {
    try {
      if (_storage == null) {
        await initialize();
      }

      final ref = _storage!.ref().child('passes/$passId.pkpass');
      await ref.delete();

      log('🗑️ Pass file deleted: $passId');
    } catch (e) {
      log('❌ Error deleting pass file: $e');
    }
  }

  /// Get all uploaded passes
  static Future<List<String>> listPasses() async {
    try {
      if (_storage == null) {
        await initialize();
      }

      final ref = _storage!.ref().child('passes');
      final result = await ref.listAll();

      final passIds = result.items.map((item) => item.name.replaceAll('.pkpass', '')).toList();

      log('📋 Found ${passIds.length} passes in Firebase Storage');
      return passIds;
    } catch (e) {
      log('❌ Error listing passes: $e');
      return [];
    }
  }
}
