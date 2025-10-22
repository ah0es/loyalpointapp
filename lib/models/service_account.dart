/// Service Account Model
///
/// Represents Google Cloud Service Account credentials
/// Used for JWT generation and OAuth token exchange
class ServiceAccount {
  final String projectId;
  final String issuerId;
  final String serviceAccountEmail;
  final String clientId;
  final String privateKeyId;
  final String privateKey;
  final String classId;

  const ServiceAccount({
    required this.projectId,
    required this.issuerId,
    required this.serviceAccountEmail,
    required this.clientId,
    required this.privateKeyId,
    required this.privateKey,
    required this.classId,
  });

  /// Get the full class ID (issuerId.classId)
  String get fullClassId => '$issuerId.$classId';

  /// Get the full object ID for a given user ID
  String getObjectId(String userId) => '$issuerId.$userId';

  /// Create from WalletConfig
  factory ServiceAccount.fromConfig() {
    return const ServiceAccount(
      projectId: 'loyaltycardapp-475919',
      issuerId: '3388000000023018874',
      serviceAccountEmail: 'wallet-service@loyaltycardapp-475919.iam.gserviceaccount.com',
      clientId: '117213026543794692236',
      privateKeyId: '85ee5746c31eb5472a4c05af166a3883848fa0e4',
      privateKey: '''-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCoiwpmtxGLgzgG
/Q4UmF61XSvAulVhcRqPD2N87TuGNY/0yoRFvKt8kEglGbi9oK8ZwwIuAA0YmAAf
OjvrujsQsBedcAicyQZUbX1WJaVYbroQ/JX0yvq8Z5F3fkKMslOQju6Vsg+ra30Q
YNp9+E7TzzWg9RRQlC1GF2niIVlzd273yP1xo+Ii7fnJiv63PB/2fD0w8oHYrwTP
W7E1yKy+9DDFWGeg4tUe8bGvOyC1SOTcL7QvTXvW6cw8WrVOSrtVle6+GB3blkC3
4cAhgjCfixrKVWaO3fjKbNv7ctaImeVDoWRzi5xERTlDzyVp/eFifEF48TRNbn8D
2DQ0f121AgMBAAECggEAE3HDDURBPRgHjorYT9j0/Ysrtow+DcQCMo9Yb3u2ZSPo
dpnR9nJZ/cDENKo0gtq3CMuo2eITS2CR4bMStv3hEupLNynLMedhQxFEp1EoM70b
20TWD2FG2cCVwDRBUkEVMfVuIg1iZb48tfcujd+SnI4TG6gv+UyMXUHrQHWPf9S6
FMhxZTrwEx3crFQP9NVT42htPTU8Y8Jplir2nvhrN0XM1FHArfCJfPh8wEpfGRCk
9f6M2n4j6uqdqjG6ozIXa5S12hM1Eal31mHZtmMzt3qV+x6GS4BkOd2GFOXElwi1
SVv3SC+E7Ray/279yy489URgD9snAwatpPSkT7oCiwKBgQDbDBI0k3zRzsicfFDZ
0VHtWMTGRTdh6mjLSENnwZ1ZFQwr9xwRG1BvIp40KGnKmXVWd+8cvyf69ujwAZRk
qej7tGRsa5AwhXC9e66kAzTHrsECBW+9ID9ok6OWrVFeIBCDIkv+oPZCAFQFrVKr
OnrnpeEjq//S4h1GydJvA5PKZwKBgQDE+d26Nl8W8MosVHQg+Vn1Ma4HqBUFnIYG
fonIZd+2yjOK9JPxF22F5yGkj9wHOFan/tEg0u3xvyjG5My7NZO+HfsZtM3ItLCn
rYYlJRrwo9/ywXubppZPoB+bR9856XGNiOeJ1PLvLBzajroxqmxb3tCDAIT1SoHk
MjPpIBH9gwKBgB+4BcLbQI3ZFa+jSMnhx61I12WmjDh/iyE0m54gqTpHE/Yh2EyZ
2fHd327KE1elFRqqT1OoUo/CxURL1kMlX3ljS89vW/fKuuKVUFqrpC7uHUC/rMiE
LOplxqCBBHFOz1VN2BdNE5vHFGOmD3yAAWAd4xYZR/gvifHAM9qjd/ktAoGAGMiv
o1xv/nzxkz5VFkkJjpZfpUr6yif1nR+Syoo26dLrRVKcwrsF5tE8JG6NasMl9CFV
wuGHWuGIie4D7JJDMqqnC4b6VYSWraJhvI68owabiPnbSaxeQUqOb4VNiwXaacqO
B4OpxXoxbzaCKvmchLq2VaVdFVf4m/PNIEoOuW0CgYA7ItKcE7Yvb2BhvK5/szog
raYlk4T5+ztOuh1VR0muY2qxPDKzYUrRG2H32yuxqsYgf1sVfdD6ipVFYufTmiUq
mjE8vOgWHNYcE6NdzDN2r+DpCSBqV8IRBGnkUhIyHM2C73o7J2+7UAt8kfXNpNFf
t6mBs0BcJa+VDC5GZxy/aA==
-----END PRIVATE KEY-----''',
      classId: 'loyalty_card_v1',
    );
  }

  @override
  String toString() {
    return 'ServiceAccount(projectId: $projectId, issuerId: $issuerId, serviceAccountEmail: $serviceAccountEmail)';
  }
}
