import 'package:flutter/material.dart';
import '../models/loyalty_card.dart';
import '../services/card_updater.dart';

/// Card Details Screen
/// 
/// Displays detailed information about a loyalty card
/// Allows updating card details and sending push notifications
class CardDetailsScreen extends StatefulWidget {
  final LoyaltyCard loyaltyCard;

  const CardDetailsScreen({
    super.key,
    required this.loyaltyCard,
  });

  @override
  State<CardDetailsScreen> createState() => _CardDetailsScreenState();
}

class _CardDetailsScreenState extends State<CardDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pointsController = TextEditingController();
  final _messageController = TextEditingController();
  
  final CardUpdater _cardUpdater = CardUpdater();
  
  bool _isUpdating = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _pointsController.text = widget.loyaltyCard.points.toString();
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Card Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
            _buildCardPreview(),
            const SizedBox(height: 24),
            _buildUpdateForm(),
            if (_errorMessage != null) _buildErrorMessage(),
            if (_successMessage != null) _buildSuccessMessage(),
            const SizedBox(height: 24),
            _buildTechnicalInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPreview() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loyalty Card',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4285F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.card_membership, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Loyalty Card',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.loyaltyCard.customerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'POINTS',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            widget.loyaltyCard.points.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'LEVEL',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            widget.loyaltyCard.level,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _buildUpdateForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Update Card',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pointsController,
                decoration: const InputDecoration(
                  labelText: 'New Points',
                  hintText: 'Enter new points value',
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Update Message',
                  hintText: 'Message to send to user (optional)',
                  prefixIcon: Icon(Icons.message),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isUpdating ? null : _updateCard,
                icon: _isUpdating 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.update),
                label: Text(_isUpdating ? 'Updating...' : 'Update Card'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
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
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
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
              child: Text(
                _successMessage!,
                style: const TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Technical Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Card ID', widget.loyaltyCard.id),
            _buildInfoRow('Class ID', widget.loyaltyCard.classId),
            _buildInfoRow('State', widget.loyaltyCard.state),
            _buildInfoRow('Barcode Value', widget.loyaltyCard.barcodeValue),
            _buildInfoRow('Background Color', widget.loyaltyCard.backgroundColor),
            _buildInfoRow('Logo URL', widget.loyaltyCard.logoUrl),
            const SizedBox(height: 16),
            const Text(
              'Update Process:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Generate OAuth JWT with service account credentials\n'
              '2. Exchange JWT for OAuth access token\n'
              '3. Call Google Wallet API to update the card\n'
              '4. Send push notification to user\'s device\n'
              '5. Card updates automatically in Google Wallet',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCard() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isUpdating = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      final newPoints = int.parse(_pointsController.text.trim());
      final message = _messageController.text.trim().isEmpty 
          ? 'Your loyalty card has been updated!'
          : _messageController.text.trim();
      
      // Update the card
      final success = await _cardUpdater.updateCard(
        objectId: widget.loyaltyCard.id,
        customerName: widget.loyaltyCard.customerName,
        points: newPoints,
        message: message,
      );
      
      if (success) {
        setState(() {
          _successMessage = 'Card updated successfully! User will receive a push notification.';
          _isUpdating = false;
        });
        
        // Update the local card data
        // In a real app, you might want to refresh from the server
      } else {
        setState(() {
          _errorMessage = 'Failed to update card. Please try again.';
          _isUpdating = false;
        });
      }
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating card: $e';
        _isUpdating = false;
      });
    }
  }
}
