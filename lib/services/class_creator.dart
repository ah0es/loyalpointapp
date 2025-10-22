import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/wallet_config.dart';
import '../models/service_account.dart';
import 'jwt_generator.dart';

/// Google Wallet Class Creator
///
/// Creates the loyalty card class in Google Wallet if it doesn't exist
/// This is required before creating loyalty card objects
class ClassCreator {
  final ServiceAccount _serviceAccount;
  final JWTGenerator _jwtGenerator;

  ClassCreator() : _serviceAccount = ServiceAccount.fromConfig(), _jwtGenerator = JWTGenerator(ServiceAccount.fromConfig());

  /// Create the loyalty card class in Google Wallet
  ///
  /// This method creates the class definition that all loyalty cards will use
  /// Must be called before creating any loyalty card objects
  Future<bool> createLoyaltyCardClass() async {
    try {
      print('🏗️ Creating loyalty card class...');

      // Get OAuth access token
      final accessToken = await _getOAuthToken();
      if (accessToken == null) {
        print('❌ Failed to get OAuth token');
        return false;
      }

      print('🔑 OAuth token obtained');

      // Create the class definition
      final classDefinition = _createClassDefinition();

      // Create class via API
      final success = await _createClassViaAPI(accessToken, classDefinition);

      if (success) {
        print('✅ Loyalty card class created successfully');
      } else {
        print('❌ Failed to create loyalty card class');
      }

      return success;
    } catch (e) {
      print('❌ Error creating loyalty card class: $e');
      return false;
    }
  }

  /// Get OAuth access token using JWT
  Future<String?> _getOAuthToken() async {
    try {
      print('🔐 Getting OAuth token for class creation...');

      // Generate JWT for OAuth
      final jwt = await _jwtGenerator.generateOAuthJWT(WalletConfig.walletObjectIssuerScope);

      print('📝 OAuth JWT generated');

      // Exchange JWT for access token
      final response = await http.post(
        Uri.parse(WalletConfig.oauthTokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer', 'assertion': jwt},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'] as String?;

        if (accessToken != null) {
          print('✅ OAuth token obtained');
          return accessToken;
        } else {
          print('❌ No access token in response');
          return null;
        }
      } else {
        print('❌ OAuth request failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting OAuth token: $e');
      return null;
    }
  }

  /// Create the class definition for loyalty cards
  Map<String, dynamic> _createClassDefinition() {
    return {
      'id': _serviceAccount.fullClassId,
      'classTemplateInfo': {
        'cardTemplateOverride': {
          'cardRowTemplateInfos': [
            {
              'twoItems': {
                'startItem': {
                  'firstValue': {
                    'fields': [
                      {'fieldPath': 'object.textModulesData["points"]'},
                    ],
                  },
                },
                'endItem': {
                  'firstValue': {
                    'fields': [
                      {'fieldPath': 'object.textModulesData["level"]'},
                    ],
                  },
                },
              },
            },
          ],
        },
      },
      'hexBackgroundColor': WalletConfig.cardBackgroundColor,
      'logo': {
        'sourceUri': {'uri': WalletConfig.logoUrl},
      },
      'cardTitle': {
        'defaultValue': {'language': 'en-US', 'value': 'Loyalty Card'},
      },
      'subheader': {
        'defaultValue': {'language': 'en-US', 'value': 'Loyalty Program'},
      },
    };
  }

  /// Create class via Google Wallet API
  Future<bool> _createClassViaAPI(String accessToken, Map<String, dynamic> classDefinition) async {
    try {
      print('📡 Creating class via API...');

      final response = await http.post(
        Uri.parse('${WalletConfig.walletApiBaseUrl}/genericClass'),
        headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'},
        body: jsonEncode(classDefinition),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Class created via API');
        return true;
      } else if (response.statusCode == 409) {
        print('ℹ️ Class already exists (409 Conflict)');
        return true; // Class already exists, which is fine
      } else {
        print('❌ API creation failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error creating class via API: $e');
      return false;
    }
  }

  /// Check if the class exists
  Future<bool> classExists() async {
    try {
      print('🔍 Checking if class exists...');

      final accessToken = await _getOAuthToken();
      if (accessToken == null) {
        return false;
      }

      final response = await http.get(
        Uri.parse('${WalletConfig.walletApiBaseUrl}/genericClass/${_serviceAccount.fullClassId}'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        print('✅ Class exists');
        return true;
      } else if (response.statusCode == 404) {
        print('❌ Class does not exist');
        return false;
      } else {
        print('❌ Error checking class: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error checking class existence: $e');
      return false;
    }
  }
}
