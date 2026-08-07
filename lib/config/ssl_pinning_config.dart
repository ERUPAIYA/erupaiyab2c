class SslPinningConfig {
  SslPinningConfig._();

  static const bool enableInProductionOnly = true;

  static const List<String> allowedHosts = <String>[
    'test.erupaiya.com',
  ];

  static const List<String> sha256Fingerprints = <String>[
    '21:54:8F:10:91:52:B6:14:3E:BB:2E:6D:5B:DC:CE:4E:B0:0A:0A:74:2F:04:C8:AE:D7:54:55:B2:68:82:17:4A',
  ];
}
