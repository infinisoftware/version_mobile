class AppConfig {
  /// Local backend: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://giftexchangeglobal.com/api/v1',
  );

  static const websiteUrl = 'https://giftexchangeglobal.com';
}
