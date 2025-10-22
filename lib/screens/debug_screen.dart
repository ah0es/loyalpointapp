import 'package:flutter/material.dart';
import '../services/google_wallet_service.dart';
import '../services/class_creator.dart';

/// Debug Screen
///
/// Helps diagnose Google Wallet setup issues
class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final GoogleWalletService _walletService = GoogleWalletService();
  final ClassCreator _classCreator = ClassCreator();

  String _status = 'Ready to test';
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Debug Google Wallet',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4285F4),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_buildStatusCard(), const SizedBox(height: 16), _buildTestButtons(), const SizedBox(height: 16), _buildTroubleshootingGuide()],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Diagnostic Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(_status, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtons() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Test Google Wallet Setup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isTesting ? null : _testClassExists,
              icon: const Icon(Icons.search),
              label: const Text('Check if Class Exists'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isTesting ? null : _createClass,
              icon: const Icon(Icons.add),
              label: const Text('Create Class'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isTesting ? null : _testSaveUrl,
              icon: const Icon(Icons.qr_code),
              label: const Text('Test Save URL Generation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingGuide() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Troubleshooting Guide', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('If QR code shows "Error" when scanned:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '1. ✅ Check Google Cloud Console:\n'
              '   • Enable Google Wallet API\n'
              '   • Verify service account has "Wallet Object Issuer" role\n'
              '   • Check project ID matches: loyaltycardapp-475919\n\n'
              '2. ✅ Test the Save URL directly:\n'
              '   • Copy the generated Save URL\n'
              '   • Open it in a browser\n'
              '   • Should show "Save to Wallet" page\n\n'
              '3. ✅ Verify Google Wallet app:\n'
              '   • Install Google Wallet app on your phone\n'
              '   • Make sure it\'s the latest version\n'
              '   • Try scanning with phone camera app\n\n'
              '4. ✅ Check credentials:\n'
              '   • Verify service account email is correct\n'
              '   • Check private key format (PKCS#8)\n'
              '   • Ensure issuer ID is correct: 3388000000023018874',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testClassExists() async {
    setState(() {
      _isTesting = true;
      _status = 'Checking if loyalty card class exists...';
    });

    try {
      final exists = await _classCreator.classExists();
      setState(() {
        _status = exists ? '✅ Class exists! This is good.' : '❌ Class does not exist. You need to create it.';
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error checking class: $e';
        _isTesting = false;
      });
    }
  }

  Future<void> _createClass() async {
    setState(() {
      _isTesting = true;
      _status = 'Creating loyalty card class...';
    });

    try {
      final created = await _classCreator.createLoyaltyCardClass();
      setState(() {
        _status = created ? '✅ Class created successfully!' : '❌ Failed to create class. Check your Google Cloud setup.';
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error creating class: $e';
        _isTesting = false;
      });
    }
  }

  Future<void> _testSaveUrl() async {
    setState(() {
      _isTesting = true;
      _status = 'Testing Save URL generation...';
    });

    try {
      final saveUrl = await _walletService.generateSaveUrl(customerName: 'Test User', points: 100);

      setState(() {
        _status =
            '✅ Save URL generated successfully!\n\n'
            'URL: ${saveUrl.substring(0, 100)}...\n\n'
            'Test this URL in your browser first!';
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _status =
            '❌ Error generating Save URL: $e\n\n'
            'This indicates a setup issue. Check the troubleshooting guide.';
        _isTesting = false;
      });
    }
  }
}
