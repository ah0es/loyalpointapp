# Apple Wallet Integration Setup Guide

This guide explains how to set up Apple Wallet integration for your Flutter loyalty card app.

## Current Implementation Status

✅ **Completed:**
- Basic Apple Wallet service structure
- Platform detection (iOS vs Android)
- Unified wallet service for both Google Wallet and Apple Wallet
- UI updates to support both wallet types
- Placeholder Apple Wallet pass generation

⚠️ **Note:** The current implementation creates placeholder Apple Wallet passes. For production use, you'll need to complete the Apple Developer setup.

## Apple Developer Setup (Required for Production)

### 1. Apple Developer Account
- Sign up for an Apple Developer account ($99/year)
- Access the Apple Developer Portal

### 2. Create Pass Type ID
1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to "Certificates, Identifiers & Profiles"
3. Click "Identifiers" → "+" → "Pass Type IDs"
4. Create a new Pass Type ID (e.g., `pass.com.yourcompany.loyalty`)
5. Note down the Pass Type ID and Team ID

### 3. Create Pass Type ID Certificate
1. In the same section, click "Certificates" → "+"
2. Select "Pass Type ID Certificate"
3. Choose your Pass Type ID
4. Upload a Certificate Signing Request (CSR)
5. Download the certificate (.cer file)
6. Convert to .p12 format for use in your app

### 4. Update Configuration
Update your `lib/config/wallet_config.dart`:

```dart
class WalletConfig {
  // ... existing Google Wallet config ...
  
  // Apple Wallet Configuration
  static const String applePassTypeId = 'pass.com.yourcompany.loyalty';
  static const String appleTeamId = 'YOUR_TEAM_ID';
  static const String applePassName = 'Loyalty Card';
  static const String appleOrganizationName = 'Your Company';
}
```

## Production Apple Wallet Implementation

### 1. Install Required Dependencies
Add to `pubspec.yaml`:

```yaml
dependencies:
  # For PKPass creation and signing
  archive: ^3.4.0
  path_provider: ^2.1.1
  crypto: ^3.0.3
  
  # For Apple Wallet integration
  pass_flutter: ^0.0.3  # If available, or use native iOS integration
```

### 2. Update Apple Wallet Service
Replace the placeholder implementation in `lib/services/apple_wallet_service.dart`:

```dart
// Real implementation would include:
// - Proper PKPass structure creation
// - Image generation (icon.png, logo.png, etc.)
// - Pass signing with Apple certificate
// - ZIP archive creation
// - Native iOS PassKit integration
```

### 3. iOS Configuration
Update `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>pass.com.yourcompany.loyalty</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>pass</string>
        </array>
    </dict>
</array>
```

### 4. Native iOS Integration
For full Apple Wallet integration, you may need to:

1. Create a native iOS module using Swift/Objective-C
2. Use PassKit framework for pass presentation
3. Handle pass updates and notifications
4. Implement pass validation

## Testing

### Current Testing (Placeholder)
- The app will generate placeholder Apple Wallet passes
- On iOS devices, it will show Apple Wallet UI
- Pass files are created but not properly signed

### Production Testing
1. Use a physical iOS device (simulator doesn't support Apple Wallet)
2. Install the app with proper certificates
3. Generate passes and test adding to Apple Wallet
4. Test pass updates and notifications

## Features Comparison

| Feature | Google Wallet | Apple Wallet |
|---------|---------------|--------------|
| QR Code Generation | ✅ | ❌ |
| Direct App Integration | ✅ | ✅ |
| Pass Updates | ✅ | ✅ |
| Push Notifications | ✅ | ✅ |
| Cross-Platform | ✅ | ❌ (iOS only) |
| Setup Complexity | Medium | High |

## Next Steps

1. **Immediate:** Test the current implementation on iOS device
2. **Short-term:** Complete Apple Developer setup
3. **Medium-term:** Implement proper PKPass generation
4. **Long-term:** Add pass updates and notifications

## Troubleshooting

### Common Issues

1. **"Pass Type ID not found"**
   - Ensure Pass Type ID is correctly configured
   - Check Apple Developer account status

2. **"Certificate not valid"**
   - Verify certificate is properly installed
   - Check certificate expiration date

3. **"Pass not adding to wallet"**
   - Ensure device supports Apple Wallet
   - Check pass structure and signing

### Debug Tools

Use the debug screen in the app to:
- Check wallet availability
- Validate pass generation
- Test pass signing

## Resources

- [Apple Wallet Developer Guide](https://developer.apple.com/wallet/)
- [PassKit Framework Documentation](https://developer.apple.com/documentation/passkit)
- [Creating Passes](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/PassKit_PG/Creating.html)
- [Flutter iOS Integration](https://flutter.dev/docs/development/platform-integration/platform-channels)

## Support

For issues with Apple Wallet integration:
1. Check Apple Developer documentation
2. Verify certificate and Pass Type ID setup
3. Test on physical iOS device
4. Review pass structure and signing process
