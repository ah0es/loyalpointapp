/// Apple Wallet Configuration
///
/// Configuration settings for Apple Wallet pass generation
/// Update these values with your actual Apple Developer credentials
class AppleWalletConfig {
  // Apple Developer Credentials
  // Replace these with your actual values from Apple Developer Portal

  /// Your Apple Developer Team ID
  /// Found in: Apple Developer Portal > Membership > Team ID
  static const String teamId = 'URUB7FFTTD';

  /// Your Pass Type ID
  /// Format: pass.com.yourcompany.loyalty
  /// Created in: Apple Developer Portal > Identifiers > Pass Type IDs
  static const String passTypeId = 'pass.com.urub7ffttd.loyalty';

  /// Your organization name
  static const String organizationName = 'Loyalty App';

  /// Pass name displayed in Apple Wallet
  static const String passName = 'Loyalty Card';

  /// Pass description
  static const String passDescription = 'Loyalty Card for earning and redeeming points';

  /// Certificate configuration
  /// Path to your P12 certificate file
  static const String certificatePath = 'assets/certificates/passcerp12.p12';

  /// Certificate password
  /// The password you set when exporting the P12 file
  static const String certificatePassword = 'Ahmed172003';

  /// Pass colors
  static const String foregroundColor = 'rgb(255, 255, 255)';
  static const String labelColor = 'rgb(255, 255, 255)';

  /// Default pass colors by level
  static const Map<String, String> levelColors = {
    'Bronze': 'rgb(205, 127, 50)',
    'Silver': 'rgb(192, 192, 192)',
    'Gold': 'rgb(255, 215, 0)',
    'Platinum': 'rgb(229, 228, 226)',
  };

  /// Default background color
  static const String defaultBackgroundColor = 'rgb(66, 133, 244)';

  /// Pass validity
  static const int passValidityDays = 365;

  /// Barcode configuration
  static const String barcodeFormat = 'PKBarcodeFormatQR';
  static const String barcodeEncoding = 'iso-8859-1';

  /// Contact information
  static const String supportEmail = 'support@loyaltyapp.com';
  static const String supportPhone = '+1-800-123-4567';
  static const String website = 'https://loyaltyapp.com';

  /// Web service configuration
  static const String webServiceUrl = 'https://loyaltyapp.com/api/passes';
  static const String authenticationToken = 'loyalty-app-auth-token-2024';

  /// Terms and conditions
  static const String termsAndConditions = 'This loyalty card is valid for earning and redeeming points. '
      'Points do not expire and are non-transferable. '
      'For full terms, visit our website.';

  /// Validate configuration
  static bool get isConfigured {
    return teamId.isNotEmpty &&
        passTypeId.isNotEmpty &&
        organizationName.isNotEmpty &&
        passTypeId.startsWith('pass.') &&
        teamId.length == 10 &&
        certificatePath.isNotEmpty &&
        certificatePassword.isNotEmpty;
  }

  /// Get configuration status message
  static String get configurationStatus {
    if (!isConfigured) {
      final issues = <String>[];
      if (teamId.isEmpty) issues.add('Team ID is empty');
      if (passTypeId.isEmpty) issues.add('Pass Type ID is empty');
      if (!passTypeId.startsWith('pass.')) issues.add('Pass Type ID must start with "pass."');
      if (teamId.length != 10) issues.add('Team ID must be exactly 10 characters');
      if (organizationName.isEmpty) issues.add('Organization name is empty');
      if (certificatePath.isEmpty) issues.add('Certificate path is empty');
      if (certificatePassword.isEmpty) issues.add('Certificate password is empty');

      return 'Apple Wallet configuration issues: ${issues.join(', ')}';
    }
    return 'Apple Wallet configured successfully.';
  }
}
