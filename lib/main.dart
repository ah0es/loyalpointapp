import 'package:flutter/material.dart';
import 'screens/enhanced_home_screen.dart';

/// Loyalty Point App
///
/// A Flutter application for generating Google Wallet loyalty cards
/// with QR code scanning functionality. Users can create loyalty cards
/// that can be added to Google Wallet via QR code scanning.
void main() {
  runApp(const LoyaltyPointApp());
}

class LoyaltyPointApp extends StatelessWidget {
  const LoyaltyPointApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loyalty Point App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Material Design 3 with Google Blue color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4285F4), // Google Blue
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF4285F4), foregroundColor: Colors.white, elevation: 0),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4285F4),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        cardTheme: CardThemeData(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      home: const EnhancedHomeScreen(),
    );
  }
}
