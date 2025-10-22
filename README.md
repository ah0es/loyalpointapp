# 🎯 Loyalty Card Generator

A beautiful Flutter web application for generating Google Wallet loyalty cards with QR code scanning functionality.

## ✨ Features

- 🎨 **Modern Design**: Beautiful Material Design 3 UI with gradients and animations
- 📱 **Google Wallet Integration**: Generate loyalty cards that can be added directly to Google Wallet
- 🔍 **QR Code Generation**: Create QR codes that users can scan with their phones
- 🏆 **Loyalty Levels**: Automatic Bronze, Silver, Gold, and Platinum level determination
- 🔐 **Secure**: Powered by Google Wallet with enterprise-grade security
- 🌐 **Web Ready**: Deployed on GitHub Pages for easy access

## 🚀 Live Demo

Visit the live application: [https://yourusername.github.io/loyalpointapp](https://yourusername.github.io/loyalpointapp)

## 🛠️ Setup Instructions

### Prerequisites

- Flutter SDK (3.16.0 or higher)
- Google Cloud Project with Wallet API enabled
- Service Account with Wallet Object Issuer permissions

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/loyalpointapp.git
   cd loyalpointapp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Google Cloud credentials**
   - Update `lib/config/wallet_config.dart` with your Google Cloud credentials
   - Ensure your service account has the "Wallet Object Issuer" role

4. **Run the application**
   ```bash
   flutter run -d chrome
   ```

## 🎨 Design Features

### Modern UI Components
- **Gradient Backgrounds**: Beautiful color gradients throughout the app
- **Card-based Layout**: Clean, organized information display
- **Smooth Animations**: Fade transitions and hover effects
- **Responsive Design**: Works perfectly on desktop and mobile

### Enhanced User Experience
- **Real-time Preview**: See your loyalty card before generating
- **One-click Actions**: Generate QR codes and copy URLs easily
- **Error Handling**: Clear, helpful error messages
- **Debug Tools**: Built-in troubleshooting for Google Wallet setup

## 🔧 Google Cloud Setup

### 1. Create Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the **Google Wallet API**

### 2. Create Service Account
1. Go to **IAM & Admin** → **Service Accounts**
2. Create a new service account
3. Download the JSON key file
4. Add the **"Wallet Object Issuer"** role

### 3. Configure Google Wallet Console
1. Go to [Google Wallet Console](https://pay.google.com/business/console)
2. Create a loyalty card class
3. Add your service account as a user with Editor role

## 📱 How to Use

1. **Enter Customer Details**
   - Customer Name: Enter the customer's name
   - Points: Enter the loyalty points (0-1000+)

2. **Generate QR Code**
   - Click "Generate QR Code" button
   - Wait for the JWT to be generated
   - View the card preview

3. **Add to Google Wallet**
   - Scan the QR code with your phone camera
   - Or click "Add to Wallet" to open directly
   - The loyalty card will be added to Google Wallet

## 🎯 Loyalty Levels

| Points | Level | Color |
|--------|-------|-------|
| 0-99 | Bronze | 🟤 |
| 100-499 | Silver | ⚪ |
| 500-999 | Gold | 🟡 |
| 1000+ | Platinum | 🟣 |

## 🚀 Deployment

### GitHub Pages Deployment

This app is automatically deployed to GitHub Pages using GitHub Actions.

1. **Push to main branch**
   ```bash
   git add .
   git commit -m "Deploy to GitHub Pages"
   git push origin main
   ```

2. **Enable GitHub Pages**
   - Go to repository Settings
   - Navigate to Pages section
   - Select "GitHub Actions" as source

3. **Access your app**
   - Visit: `https://yourusername.github.io/loyalpointapp`

### Manual Deployment

```bash
# Build for web
flutter build web --release

# Deploy to any web server
# Copy build/web contents to your web server
```

## 🔧 Troubleshooting

### Common Issues

1. **"Could not find necessary class" error**
   - Ensure the loyalty card class exists in Google Wallet Console
   - Check that the class is published/active
   - Verify service account has proper permissions

2. **"Permission denied" error**
   - Add service account to Google Wallet Console as a user
   - Ensure service account has "Wallet Object Issuer" role
   - Check that Google Wallet API is enabled

3. **"card_title must be set" error**
   - This is fixed in the current version
   - Ensure you're using the latest code

### Debug Tools

Use the built-in debug screen to diagnose issues:
- Click the "Debug Google Wallet Setup" button
- Test class existence and creation
- Verify OAuth token generation

## 📁 Project Structure

```
lib/
├── config/
│   └── wallet_config.dart          # Google Cloud credentials
├── models/
│   ├── loyalty_card.dart           # Loyalty card data model
│   └── service_account.dart        # Service account model
├── services/
│   ├── jwt_generator.dart          # JWT generation and signing
│   ├── google_wallet_service.dart  # Google Wallet API integration
│   ├── class_creator.dart          # Class creation service
│   └── card_updater.dart           # Card update service
├── screens/
│   ├── enhanced_home_screen.dart   # Main UI with modern design
│   ├── home_screen.dart            # Original home screen
│   └── debug_screen.dart           # Debug and troubleshooting
└── main.dart                       # App entry point
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Google Wallet API for loyalty card functionality
- Flutter team for the amazing framework
- Material Design for beautiful UI components

## 📞 Support

If you encounter any issues:

1. Check the troubleshooting section above
2. Use the built-in debug tools
3. Open an issue on GitHub
4. Contact the development team

---

**Made with ❤️ using Flutter and Google Wallet**