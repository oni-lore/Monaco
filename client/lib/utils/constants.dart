class ApiConstants {
  // In production, this would come from environment config
  // For local dev, use your local IP (e.g., 10.0.2.2 for Android emulator)
  // For production, use your backend URL
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
