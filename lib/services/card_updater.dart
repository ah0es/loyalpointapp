import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/wallet_config.dart';
import '../models/loyalty_card.dart';
import '../models/service_account.dart';
import 'jwt_generator.dart';

/// Card Updater Service
/// 
/// Handles updating loyalty cards via Google Wallet API
/// Implements OAuth token exchange and API calls for card updates
class CardUpdater {
  final ServiceAccount _serviceAccount;
  final JWTGenerator _jwtGenerator;

  CardUpdater()
      : _serviceAccount = ServiceAccount.fromConfig(),
        _jwtGenerator = JWTGenerator(ServiceAccount.fromConfig());

  /// Update loyalty card via Google Wallet API
  /// 
  /// Exchanges JWT for OAuth token, then updates the card with new data
  /// Sends push notification to user's device
  Future<bool> updateCard({
    required String objectId,
    required String customerName,
    required int points,
    required String message,
  }) async {
    try {
      print('🔄 Updating loyalty card: $objectId');
      
      // Get OAuth access token
      final accessToken = await _getOAuthToken();
      if (accessToken == null) {
        print('❌ Failed to get OAuth token');
        return false;
      }
      
      print('🔑 OAuth token obtained');
      
      // Create updated loyalty card
      final updatedCard = await _createUpdatedCard(
        objectId: objectId,
        customerName: customerName,
        points: points,
        message: message,
      );
      
      // Update card via API
      final success = await _updateCardViaAPI(
        accessToken: accessToken,
        objectId: objectId,
        updatedCard: updatedCard,
      );
      
      if (success) {
        print('✅ Card updated successfully');
      } else {
        print('❌ Failed to update card');
      }
      
      return success;
      
    } catch (e) {
      print('❌ Error updating card: $e');
      return false;
    }
  }

  /// Get OAuth access token using JWT
  /// 
  /// Creates a JWT for OAuth and exchanges it for an access token
  /// Required for making authenticated API calls to Google Wallet
  Future<String?> _getOAuthToken() async {
    try {
      print('🔐 Getting OAuth token...');
      
      // Generate JWT for OAuth
      final jwt = await _jwtGenerator.generateOAuthJWT(
        WalletConfig.walletObjectIssuerScope,
      );
      
      print('📝 OAuth JWT generated');
      
      // Exchange JWT for access token
      final response = await http.post(
        Uri.parse(WalletConfig.oauthTokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': jwt,
        },
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

  /// Create updated loyalty card with new data
  /// 
  /// Generates a new loyalty card object with updated points and level
  Future<LoyaltyCard> _createUpdatedCard({
    required String objectId,
    required String customerName,
    required int points,
    required String message,
  }) async {
    // Determine new level based on points
    String level;
    if (points >= WalletConfig.levelThresholds['Platinum']!) {
      level = 'Platinum';
    } else if (points >= WalletConfig.levelThresholds['Gold']!) {
      level = 'Gold';
    } else if (points >= WalletConfig.levelThresholds['Silver']!) {
      level = 'Silver';
    } else {
      level = 'Bronze';
    }
    
    // Create text modules
    final textModules = [
      TextModule(
        id: 'points',
        header: 'POINTS',
        body: points.toString(),
      ),
      TextModule(
        id: 'level',
        header: 'LEVEL',
        body: level,
      ),
    ];
    
    // Create barcode (keep same value for consistency)
    final barcode = Barcode(
      type: 'QR_CODE',
      value: objectId.split('.').last, // Extract user ID from object ID
      alternateText: objectId.split('.').last,
    );
    
    // Create updated loyalty card
    return LoyaltyCard(
      id: objectId,
      classId: _serviceAccount.fullClassId,
      state: 'ACTIVE',
      customerName: customerName,
      points: points,
      level: level,
      barcodeValue: objectId.split('.').last,
      cardTitle: 'Loyalty Card',
      header: customerName,
      backgroundColor: WalletConfig.cardBackgroundColor,
      logoUrl: WalletConfig.logoUrl,
      textModules: textModules,
      barcode: barcode,
    );
  }

  /// Update card via Google Wallet API
  /// 
  /// Makes authenticated API call to update the loyalty card
  /// Includes push notification message
  Future<bool> _updateCardViaAPI({
    required String accessToken,
    required String objectId,
    required LoyaltyCard updatedCard,
  }) async {
    try {
      print('📡 Updating card via API...');
      
      // Convert card to Google Wallet object format
      final walletObject = updatedCard.toGoogleWalletObject();
      
      // Add messages for push notification
      walletObject['messages'] = [
        {
          'action': 'TEXT_AND_NOTIFY',
          'messageType': 'TEXT_AND_NOTIFY',
          'body': 'Your loyalty card has been updated!',
        }
      ];
      
      // Make PATCH request to update the object
      final response = await http.patch(
        Uri.parse('${WalletConfig.walletApiBaseUrl}/genericObject/$objectId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(walletObject),
      );
      
      if (response.statusCode == 200) {
        print('✅ Card updated via API');
        return true;
      } else {
        print('❌ API update failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
      
    } catch (e) {
      print('❌ Error updating card via API: $e');
      return false;
    }
  }

  /// Send push notification to user
  /// 
  /// Sends a push notification to the user's device about the card update
  Future<bool> sendPushNotification({
    required String objectId,
    required String message,
  }) async {
    try {
      print('📱 Sending push notification...');
      
      final accessToken = await _getOAuthToken();
      if (accessToken == null) {
        return false;
      }
      
      // Create message object
      final messageObject = {
        'messages': [
          {
            'action': 'TEXT_AND_NOTIFY',
            'messageType': 'TEXT_AND_NOTIFY',
            'body': message,
          }
        ]
      };
      
      // Send message via API
      final response = await http.patch(
        Uri.parse('${WalletConfig.walletApiBaseUrl}/genericObject/$objectId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(messageObject),
      );
      
      if (response.statusCode == 200) {
        print('✅ Push notification sent');
        return true;
      } else {
        print('❌ Push notification failed: ${response.statusCode}');
        return false;
      }
      
    } catch (e) {
      print('❌ Error sending push notification: $e');
      return false;
    }
  }
}
