import 'dart:io';
import 'dart:developer';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// GitHub Apple Wallet Service
///
/// Handles uploading .pkpass files to GitHub repository
/// and generating public URLs for Apple Wallet QR codes
///
/// This is a FREE alternative to Firebase Storage!
class GitHubAppleWalletService {
  // Your actual GitHub repository details
  static const String _githubUsername = 'ah0es'; // Your GitHub username
  static const String _repositoryName = 'loyalpointapp'; // Your repository name
  static const String _githubToken = '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'; // Your GitHub personal access token

  static String get _baseUrl => 'https://$_githubUsername.github.io/$_repositoryName/passes';

  /// Upload .pkpass file to GitHub repository
  ///
  /// Returns the public URL that can be used in QR codes
  static Future<String> uploadPassFile(String localFilePath, String passId) async {
    try {
      log('📤 Uploading .pkpass file to GitHub...');
      log('📁 Local file: $localFilePath');
      log('🆔 Pass ID: $passId');

      // Read the file
      final file = File(localFilePath);
      final fileBytes = await file.readAsBytes();
      final fileContent = base64Encode(fileBytes);

      // GitHub API endpoint for creating/updating files
      final apiUrl = 'https://api.github.com/repos/$_githubUsername/$_repositoryName/contents/passes/$passId.pkpass';

      // Prepare the request body
      final requestBody = {'message': 'Add Apple Wallet pass: $passId', 'content': fileContent, 'branch': 'main'};

      // Make the API request
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'token $_githubToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final publicUrl = '$_baseUrl/$passId.pkpass';
        log('✅ File uploaded successfully to GitHub');
        log('🔗 Public URL: $publicUrl');
        return publicUrl;
      } else {
        throw Exception('GitHub API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('❌ Error uploading to GitHub: $e');
      rethrow;
    }
  }

  /// Generate Apple Wallet URL for QR code
  ///
  /// This is the URL that should be encoded in the QR code
  static Future<String> generateAppleWalletUrl(String localFilePath, String passId) async {
    try {
      // Upload the .pkpass file to GitHub
      final publicUrl = await uploadPassFile(localFilePath, passId);

      log('🍎 Apple Wallet URL generated via GitHub');
      log('📱 iPhone will open this URL in Safari');
      log('✅ Ready for QR code generation!');

      return publicUrl;
    } catch (e) {
      log('❌ Error generating Apple Wallet URL: $e');
      rethrow;
    }
  }

  /// Delete pass file from GitHub repository
  static Future<void> deletePassFile(String passId) async {
    try {
      log('🗑️ Deleting pass file from GitHub: $passId');

      // First, get the file's SHA (required for deletion)
      final apiUrl = 'https://api.github.com/repos/$_githubUsername/$_repositoryName/contents/passes/$passId.pkpass';

      final getResponse = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'token $_githubToken',
        },
      );

      if (getResponse.statusCode == 200) {
        final fileData = jsonDecode(getResponse.body);
        final sha = fileData['sha'];

        // Delete the file
        final deleteResponse = await http.delete(
          Uri.parse(apiUrl),
          headers: {
            'Authorization': 'token $_githubToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'message': 'Delete Apple Wallet pass: $passId', 'sha': sha, 'branch': 'main'}),
        );

        if (deleteResponse.statusCode == 200) {
          log('✅ Pass file deleted from GitHub');
        } else {
          log('⚠️ Error deleting file: ${deleteResponse.statusCode}');
        }
      } else {
        log('⚠️ File not found on GitHub');
      }
    } catch (e) {
      log('❌ Error deleting pass file: $e');
    }
  }

  /// Get all uploaded passes from GitHub
  static Future<List<String>> listPasses() async {
    try {
      log('📋 Listing passes from GitHub...');

      final apiUrl = 'https://api.github.com/repos/$_githubUsername/$_repositoryName/contents/passes';

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'token $_githubToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> files = jsonDecode(response.body);
        final passIds = files
            .where((file) => file['name'].toString().endsWith('.pkpass'))
            .map((file) => file['name'].toString().replaceAll('.pkpass', ''))
            .toList();

        log('📋 Found ${passIds.length} passes on GitHub');
        return passIds;
      } else {
        log('❌ Error listing passes: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('❌ Error listing passes: $e');
      return [];
    }
  }

  /// Check if GitHub is properly configured
  static bool get isConfigured {
    return _githubUsername == 'ah0es' && _repositoryName == 'loyalpointapp' && _githubToken != 'your-token';
  }

  /// Get setup instructions
  static String get setupInstructions => '''
GitHub Configuration Complete! 🎉

✅ GitHub Username: ah0es (configured)
✅ Repository Name: loyalpointapp (configured)
✅ GitHub Personal Access Token: (configured)

Your Apple Wallet passes will be available at:
https://ah0es.github.io/loyalpointapp/passes/

Ready to upload .pkpass files to GitHub!
''';
}
