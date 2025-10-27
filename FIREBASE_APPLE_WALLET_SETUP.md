# Firebase Apple Wallet Setup Guide

This guide explains how to set up Firebase for hosting Apple Wallet passes.

## 🎯 **Why Firebase for Apple Wallet?**

- ✅ **HTTPS URLs** - Required for Apple Wallet
- ✅ **Public Access** - iPhones can download .pkpass files
- ✅ **Reliable** - No localhost or network issues
- ✅ **Scalable** - Handle many passes
- ✅ **Free Tier** - Generous free usage

## 🛠️ **Setup Steps**

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `loyalty-card-app`
4. Enable Google Analytics (optional)
5. Click "Create project"

### 2. Enable Firebase Storage

1. In Firebase Console, go to "Storage"
2. Click "Get started"
3. Choose "Start in test mode" (for development)
4. Select location (choose closest to your users)
5. Click "Done"

### 3. Configure Storage Rules

In Firebase Console → Storage → Rules, update to:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow public read access to passes
    match /passes/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null; // Only authenticated users can upload
    }
  }
}
```

### 4. Get Firebase Configuration

1. In Firebase Console, go to Project Settings
2. Scroll down to "Your apps"
3. Click "Add app" → Web app
4. Register app with nickname: `loyalty-card-web`
5. Copy the Firebase config object

### 5. Add Firebase Config to Flutter

Create `lib/firebase_options.dart`:

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    iosBundleId: 'com.yourcompany.loyalpointapp',
  );

  // Add other platforms as needed
}
```

### 6. Initialize Firebase in main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

## 🧪 **Testing the Setup**

### 1. Run the App
```bash
flutter run -d ios
```

### 2. Generate QR Code
- Enter customer name and points
- Click "Generate QR Code"
- You should see logs like:
  ```
  🔥 Firebase Storage initialized
  📤 Uploading .pkpass file to Firebase Storage...
  ✅ File uploaded successfully
  🔗 Public URL: https://storage.googleapis.com/your-bucket/passes/abc123.pkpass
  ```

### 3. Test QR Scanning
- Scan the QR code with your iPhone
- Safari should open the Firebase URL
- Apple Wallet should open with the pass preview

## 🔧 **Troubleshooting**

### Common Issues:

1. **"Firebase not initialized"**
   - Make sure you added Firebase config
   - Check that `firebase_options.dart` exists

2. **"Permission denied"**
   - Check Firebase Storage rules
   - Make sure passes folder is publicly readable

3. **"No usable data found"**
   - QR code should now contain HTTPS URL, not data URL
   - Test the URL directly in Safari first

4. **"Pass not adding to wallet"**
   - Check that .pkpass file is valid
   - Verify Apple Developer certificates

## 🚀 **Production Considerations**

### Security:
- Use Firebase Authentication for uploads
- Implement proper access controls
- Monitor usage and costs

### Performance:
- Use Firebase CDN for faster downloads
- Implement caching strategies
- Monitor storage usage

### Updates:
- Implement pass update notifications
- Use Apple Push Notification Service
- Track pass usage analytics

## 📱 **Expected Flow**

1. **App generates .pkpass file** ✅
2. **Uploads to Firebase Storage** ✅
3. **Gets public HTTPS URL** ✅
4. **QR code contains HTTPS URL** ✅
5. **iPhone scans QR** → Opens Safari ✅
6. **Safari downloads .pkpass** ✅
7. **Apple Wallet opens** ✅
8. **User adds to wallet** ✅

This is the **correct and reliable way** to implement Apple Wallet QR codes! 🎉
