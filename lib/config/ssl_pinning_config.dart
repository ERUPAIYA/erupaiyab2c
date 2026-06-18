class SslPinningConfig {
  SslPinningConfig._();

  static const bool enableInProductionOnly = true;

  static const List<String> allowedHosts = <String>[
    'test.erupaiya.com',
  ];

  static const List<String> sha256Fingerprints = <String>[
    'BF:1D:23:EB:56:8B:E1:70:4A:E2:66:3D:05:21:23:7B:31:34:A5:81:CF:35:7E:D4:A8:25:AD:D8:F8:19:E5:13',
  ];
}
