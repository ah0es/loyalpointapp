/// Loyalty Card Model
///
/// Represents a loyalty card that can be added to Google Wallet
/// Contains all necessary data to generate a Google Wallet Loyalty Object
class LoyaltyCard {
  final String id;
  final String classId;
  final String state;
  final String customerName;
  final int points;
  final String level;
  final String barcodeValue;
  final String cardTitle;
  final String header;
  final String backgroundColor;
  final String logoUrl;
  final List<TextModule> textModules;
  final Barcode barcode;

  const LoyaltyCard({
    required this.id,
    required this.classId,
    required this.state,
    required this.customerName,
    required this.points,
    required this.level,
    required this.barcodeValue,
    required this.cardTitle,
    required this.header,
    required this.backgroundColor,
    required this.logoUrl,
    required this.textModules,
    required this.barcode,
  });

  /// Convert to Google Wallet Loyalty Object format
  Map<String, dynamic> toGoogleWalletObject() {
    return {
      'id': id,
      'classId': classId,
      'state': state,
      'cardTitle': {
        'defaultValue': {'language': 'en-US', 'value': cardTitle},
      },
      'header': {
        'defaultValue': {'language': 'en-US', 'value': header},
      },
      'accountName': customerName,
      'loyaltyPoints': {'label': 'Points', 'balance': points.toString()},
      'loyaltyPointsLabel': 'Points',
      'secondaryLoyaltyPoints': {'label': 'Level', 'balance': level},
      'barcode': barcode.toMap(),
      'textModulesData': textModules.map((module) => module.toMap()).toList(),
    };
  }

  /// Create a copy with updated values
  LoyaltyCard copyWith({
    String? id,
    String? classId,
    String? state,
    String? customerName,
    int? points,
    String? level,
    String? barcodeValue,
    String? cardTitle,
    String? header,
    String? backgroundColor,
    String? logoUrl,
    List<TextModule>? textModules,
    Barcode? barcode,
  }) {
    return LoyaltyCard(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      state: state ?? this.state,
      customerName: customerName ?? this.customerName,
      points: points ?? this.points,
      level: level ?? this.level,
      barcodeValue: barcodeValue ?? this.barcodeValue,
      cardTitle: cardTitle ?? this.cardTitle,
      header: header ?? this.header,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      logoUrl: logoUrl ?? this.logoUrl,
      textModules: textModules ?? this.textModules,
      barcode: barcode ?? this.barcode,
    );
  }

  @override
  String toString() {
    return 'LoyaltyCard(id: $id, customerName: $customerName, points: $points, level: $level)';
  }
}

/// Text Module for Google Wallet cards
class TextModule {
  final String id;
  final String header;
  final String body;

  const TextModule({required this.id, required this.header, required this.body});

  Map<String, dynamic> toMap() {
    return {'id': id, 'header': header, 'body': body};
  }
}

/// Barcode for Google Wallet cards
class Barcode {
  final String type;
  final String value;
  final String alternateText;

  const Barcode({required this.type, required this.value, required this.alternateText});

  Map<String, dynamic> toMap() {
    return {'type': type, 'value': value, 'alternateText': alternateText};
  }
}
