import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import '../services/unified_wallet_service.dart';
import 'debug_screen.dart';

/// Enhanced Home Screen with Modern Design
///
/// Features beautiful Material Design 3 UI with gradients and animations
class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _pointsController = TextEditingController();

  final UnifiedWalletService _walletService = UnifiedWalletService();

  WalletPassResult? _walletResult;
  bool _isGenerating = false;
  String? _errorMessage;
  String? _successMessage;
  Map<String, dynamic>? _cardPreview;
  WalletAvailability? _walletAvailability;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  /// Safely check if running on iOS
  /// Returns false for web and other unsupported platforms
  bool get _isIOS {
    try {
      return !kIsWeb && Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();
    _checkWalletAvailability();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _customerNameController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Loyalty Card Generator',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4285F4),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DebugScreen()));
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildHeroSection(),
              const SizedBox(height: 24),
              _buildForm(),
              const SizedBox(height: 24),
              if (_cardPreview != null) _buildCardPreview(),
              if (_walletResult != null) _buildWalletResult(),
              if (_errorMessage != null) _buildErrorMessage(),
              if (_successMessage != null) _buildSuccessMessage(),
              const SizedBox(height: 24),
              _buildFeatures(),
              const SizedBox(height: 24),
              _buildDebugButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF4285F4), const Color(0xFF34A853), const Color(0xFFFBBC04)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF4285F4).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(50)),
              child: const Icon(Icons.card_membership, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loyalty Card Generator',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _isIOS
                  ? 'Create stunning loyalty cards that users can add directly to their Apple Wallet or Google Wallet'
                  : 'Create stunning loyalty cards that users can add directly to their Google Wallet',
              style: const TextStyle(fontSize: 18, color: Colors.white70, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(25)),
              child: Text(
                _isIOS ? '✨ Powered by Apple Wallet & Google Wallet' : '✨ Powered by Google Wallet',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Colors.grey[50]!]),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF4285F4).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.person_add, color: Color(0xFF4285F4), size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Text('Customer Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _customerNameController,
                  decoration: InputDecoration(
                    labelText: 'Customer Name',
                    hintText: 'Enter customer name',
                    prefixIcon: const Icon(Icons.person, color: Color(0xFF4285F4)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF4285F4), width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter customer name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _pointsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Points',
                    hintText: 'Enter points',
                    prefixIcon: const Icon(Icons.stars, color: Color(0xFF4285F4)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF4285F4), width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter points';
                    }
                    final points = int.tryParse(value.trim());
                    if (points == null || points < 0) {
                      return 'Please enter valid points';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateQRCode,
                  icon: _isGenerating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.qr_code),
                  label: Text(_isGenerating ? 'Generating...' : 'Generate QR Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardPreview() {
    if (_cardPreview == null) return const SizedBox.shrink();

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Colors.grey[50]!]),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF4285F4).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.credit_card, color: Color(0xFF4285F4), size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Text('Card Preview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFF4285F4), const Color(0xFF34A853)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: const Color(0xFF4285F4).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.card_membership, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Loyalty Card',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _cardPreview!['customerName'],
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('POINTS', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 6),
                              Text(
                                _cardPreview!['points'].toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('LEVEL', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 6),
                              Text(
                                _cardPreview!['level'],
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletResult() {
    if (_walletResult == null) return const SizedBox.shrink();

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Colors.grey[50]!]),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: _walletResult!.type == WalletType.apple ? Colors.black.withOpacity(0.1) : const Color(0xFF4285F4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(_walletResult!.type == WalletType.apple ? Icons.phone_iphone : Icons.qr_code,
                        color: _walletResult!.type == WalletType.apple ? Colors.black : const Color(0xFF4285F4), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(_walletResult!.type == WalletType.apple ? 'Apple Wallet Pass' : 'Google Wallet QR Code',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_walletResult!.type == WalletType.google && _walletResult!.data != null) ...[
                // Google Wallet QR Code
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: QrImageView(data: _walletResult!.data!, version: QrVersions.auto, size: 250.0, backgroundColor: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Scan this QR code with your phone camera to add the loyalty card to Google Wallet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ] else if (_walletResult!.type == WalletType.apple && _walletResult!.data != null) ...[
                // Apple Wallet QR Code
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: QrImageView(data: _walletResult!.data!, version: QrVersions.auto, size: 250.0, backgroundColor: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Scan this QR code with your iPhone camera or tap "Open in Safari" to download the pass',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Show the pkpass URL under the QR for easy copying
                SelectableText(
                  _walletResult!.data!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        print('🎯 Button pressed!');
                        _addToWallet();
                      },
                      icon: Icon(_walletResult!.type == WalletType.apple ? Icons.language : Icons.open_in_browser),
                      label: Text(_walletResult!.type == WalletType.apple ? 'Open in Safari' : 'Add to Google Wallet'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _walletResult!.type == WalletType.apple ? Colors.black : const Color(0xFF34A853),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                    ),
                  ),
                  if ((_walletResult!.type == WalletType.google || _walletResult!.type == WalletType.apple) && _walletResult!.data != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _walletResult!.data!));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL copied to clipboard!')));
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy URL'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _walletResult!.type == WalletType.apple ? Colors.black : const Color(0xFF4285F4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Colors.grey[50]!]),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Features', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildFeatureItem(
                icon: Icons.qr_code,
                title: 'QR Code Generation',
                description: 'Generate QR codes that users can scan to add cards to Google Wallet',
              ),
              _buildFeatureItem(
                icon: Icons.phone_iphone,
                title: 'Apple Wallet Support',
                description: 'Create PKPass files for direct Apple Wallet integration on iOS devices',
              ),
              _buildFeatureItem(
                icon: Icons.card_membership,
                title: 'Loyalty Cards',
                description: 'Create beautiful loyalty cards with points and levels',
              ),
              _buildFeatureItem(
                  icon: Icons.security,
                  title: 'Secure',
                  description: _isIOS
                      ? 'Powered by Apple Wallet and Google Wallet with enterprise-grade security'
                      : 'Powered by Google Wallet with enterprise-grade security'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF4285F4).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF4285F4), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugButton() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Having Issues?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('If the QR code shows "Error" when scanned, use the debug tool to diagnose the issue.', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DebugScreen()));
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('Debug Google Wallet Setup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    if (_successMessage == null) return const SizedBox.shrink();

    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_successMessage!, style: const TextStyle(color: Colors.green)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateQRCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _successMessage = null;
      _walletResult = null;
      _cardPreview = null;
    });

    try {
      final customerName = _customerNameController.text.trim();
      final points = int.parse(_pointsController.text.trim());

      // Validate input
      final validationError = _walletService.validateInput(customerName, points.toString());
      if (validationError != null) {
        setState(() {
          _errorMessage = validationError;
          _isGenerating = false;
        });
        return;
      }

      // Get card preview
      _cardPreview = _walletService.getCardPreview(customerName: customerName, points: points);

      // Generate wallet pass (automatically detects platform)
      _walletResult = await _walletService.generateWalletPass(customerName: customerName, points: points);

      if (_walletResult!.success) {
        setState(() {
          _successMessage =
              _walletResult!.type == WalletType.apple ? 'Apple Wallet pass generated successfully!' : 'Google Wallet QR code generated successfully!';
          _isGenerating = false;
        });
      } else {
        setState(() {
          // Show error message but still allow QR code to be displayed
          _errorMessage = _walletResult!.message;
          _isGenerating = false;
        });
      }
    } catch (e) {
      String errorMessage = 'Error generating wallet pass: $e';

      // Provide more specific error messages
      if (e.toString().contains('Failed to create loyalty card class')) {
        errorMessage = 'Wallet setup issue. Please check your credentials and ensure the APIs are enabled.';
      } else if (e.toString().contains('OAuth')) {
        errorMessage = 'Authentication failed. Please check your service account credentials.';
      } else if (e.toString().contains('JWT')) {
        errorMessage = 'Token generation failed. Please check your private key format.';
      }

      setState(() {
        _errorMessage = errorMessage;
        _isGenerating = false;
      });
    }
  }

  /// Check wallet availability on app startup
  Future<void> _checkWalletAvailability() async {
    try {
      _walletAvailability = await _walletService.checkWalletAvailability();
      log('Wallet availability: ${_walletAvailability?.message}');
    } catch (e) {
      log('Error checking wallet availability: $e');
    }
  }

  /// Add pass to wallet
  Future<void> _addToWallet() async {
    print('🎯 _addToWallet called');
    print('🎯 _walletResult: $_walletResult');

    if (_walletResult == null) {
      print('❌ _walletResult is null');
      return;
    }

    print('🎯 Wallet type: ${_walletResult!.type}');
    print('🎯 Wallet data: ${_walletResult!.data}');

    try {
      print('🎯 Calling _walletService.addPassToWallet...');
      final success = await _walletService.addPassToWallet(_walletResult!);
      print('🎯 addPassToWallet result: $success');

      if (success) {
        print('✅ Wallet operation successful');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_walletResult!.type == WalletType.apple ? 'Opening Safari to download pass...' : 'Opening Google Wallet...'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('❌ Wallet operation failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add pass to wallet'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error in _addToWallet: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding pass to wallet: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
