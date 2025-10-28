import 'dart:convert';

class PassBuilder {
  // Updated with your new certificate details
  static const String teamIdentifier = 'URUB7FFTTD'; // Your Team ID
  static const String passTypeIdentifier = 'pass.com.gemma.loyalty'; // Your Pass Type ID
  static const String organizationName = 'GEMMA TECHNOLOGY COMPANY WLL';

  /// Generates pass.json content
  static Map<String, dynamic> createPassJson({
    required String serialNumber,
    required String description,
    required String eventName,
    required String eventDate,
    String? barcodeMessage,
  }) {
    return {
      // ===== REQUIRED FIELDS =====
      'formatVersion': 1,
      'passTypeIdentifier': passTypeIdentifier, // Must match certificate!
      'teamIdentifier': teamIdentifier, // Must match certificate!
      'serialNumber': serialNumber, // Unique per pass (use UUID or timestamp)
      'organizationName': organizationName,
      'description': description, // Brief description for accessibility

      // ===== VISUAL STYLE =====
      'eventTicket': {
        // Primary field (large, prominent)
        'primaryFields': [
          {
            'key': 'event',
            'label': 'EVENT',
            'value': eventName,
          }
        ],
        // Secondary fields (below primary)
        'secondaryFields': [
          {
            'key': 'date',
            'label': 'DATE',
            'value': eventDate,
          }
        ],
        // Auxiliary fields (additional details)
        'auxiliaryFields': [
          {
            'key': 'location',
            'label': 'VENUE',
            'value': 'Conference Hall A',
          }
        ],
        // Back fields (flip side of pass)
        'backFields': [
          {
            'key': 'terms',
            'label': 'TERMS AND CONDITIONS',
            'value': 'This ticket is non-transferable. Valid for one entry only.',
          }
        ],
      },

      // ===== COLORS (RGB format) =====
      'backgroundColor': 'rgb(60, 65, 76)', // Dark gray
      'foregroundColor': 'rgb(255, 255, 255)', // White text
      'labelColor': 'rgb(200, 200, 200)', // Light gray labels

      // ===== BARCODE (Optional) =====
      if (barcodeMessage != null)
        'barcodes': [
          {
            'message': barcodeMessage, // Data encoded in barcode
            'format': 'PKBarcodeFormatQR', // QR code
            'messageEncoding': 'iso-8859-1',
          }
        ],

      // ===== RELEVANCE (Optional - shows on lock screen at location/time) =====
      'relevantDate': DateTime.now().add(Duration(days: 7)).toIso8601String(),
    };
  }

  /// Converts pass data to JSON bytes
  static List<int> toJsonBytes(Map<String, dynamic> passData) {
    return utf8.encode(json.encode(passData));
  }
}
