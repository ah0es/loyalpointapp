import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/google_wallet_service.dart';
import 'debug_screen.dart';

/// Home Screen
///
/// Main screen for generating loyalty cards and QR codes
/// Features modern Material Design 3 UI with Google Blue color scheme
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _pointsController = TextEditingController();

  final GoogleWalletService _walletService = GoogleWalletService();

  String? _saveUrl;
  bool _isGenerating = false;
  String? _errorMessage;
  String? _successMessage;
  Map<String, dynamic>? _cardPreview;

  @override
  void dispose() {
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
        backgroundColor: const Color(0xFF4285F4), // Google Blue
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildForm(),
            const SizedBox(height: 24),
            if (_cardPreview != null) _buildCardPreview(),
            if (_saveUrl != null) _buildQRCode(),
            if (_errorMessage != null) _buildErrorMessage(),
            if (_successMessage != null) _buildSuccessMessage(),
            const SizedBox(height: 24),
            _buildDebugButton(),
            const SizedBox(height: 16),
            _buildTechnicalDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFF4285F4), const Color(0xFF34A853)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(50)),
              child: const Icon(Icons.card_membership, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'Loyalty Card Generator',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Create stunning loyalty cards that users can add directly to their Google Wallet',
              style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: const Text(
                '✨ Powered by Google Wallet',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Colors.grey[50]!]),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF4285F4).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.person_add, color: Color(0xFF4285F4), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Customer Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    hintText: 'Enter customer name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Customer name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pointsController,
                  decoration: const InputDecoration(
                    labelText: 'Loyalty Points',
                    hintText: 'Enter points (0-9999)',
                    prefixIcon: Icon(Icons.stars),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Points is required';
                    }
                    final points = int.tryParse(value.trim());
                    if (points == null) {
                      return 'Please enter a valid number';
                    }
                    if (points < 0) {
                      return 'Points cannot be negative';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Card Preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF4285F4), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.card_membership, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Loyalty Card',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _cardPreview!['customerName'],
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('POINTS', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(
                            _cardPreview!['points'].toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('LEVEL', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(
                            _cardPreview!['level'],
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCode() {
    if (_saveUrl == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text('QR Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: QrImageView(data: _saveUrl!, version: QrVersions.auto, size: 200.0, backgroundColor: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan this QR code with your phone camera to add the loyalty card to Google Wallet',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _walletService.launchSaveUrl(_saveUrl!),
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Add Directly to Wallet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // Copy Save URL to clipboard
                Clipboard.setData(ClipboardData(text: _saveUrl!));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save URL copied to clipboard! Test it in your browser.')));
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Save URL'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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

  Widget _buildDebugButton() {
    return Card(
      elevation: 2,
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

  Widget _buildTechnicalDetails() {
    return ExpansionTile(
      title: const Text('Technical Details', style: TextStyle(fontWeight: FontWeight.bold)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How it works:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                '1. Enter customer details and points\n'
                '2. Generate JWT token with RSA-SHA256 signing\n'
                '3. Create Google Wallet Save URL\n'
                '4. Generate QR code containing the URL\n'
                '5. User scans QR code with phone camera\n'
                '6. Google Wallet opens and adds the loyalty card',
              ),
              const SizedBox(height: 16),
              if (_saveUrl != null) ...[
                const Text('Generated Save URL:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                  child: Text(_saveUrl!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Troubleshooting:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                '• If QR code doesn\'t work, ensure Google Wallet app is installed\n'
                '• Check that Google Cloud Wallet API is enabled\n'
                '• Verify service account has Wallet Object Issuer role\n'
                '• Make sure the loyalty card class exists in Google Cloud\n'
                '• Test the Save URL directly in a browser first',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _generateQRCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _successMessage = null;
      _saveUrl = null;
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

      // Generate Save URL
      _saveUrl = await _walletService.generateSaveUrl(customerName: customerName, points: points);

      setState(() {
        _successMessage = 'QR code generated successfully!';
        _isGenerating = false;
      });
    } catch (e) {
      String errorMessage = 'Error generating QR code: $e';

      // Provide more specific error messages
      if (e.toString().contains('Failed to create loyalty card class')) {
        errorMessage = 'Google Wallet setup issue. Please check your Google Cloud credentials and ensure the Wallet API is enabled.';
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
}
