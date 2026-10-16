class ApiConstants {
  // Override at build time with: --dart-define=API_BASE_URL=http://<host>:3000
  // Default is the Android emulator's localhost alias (10.0.2.2).
  // For physical devices, use your machine's LAN IP (e.g., http://192.168.1.50:3000).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
