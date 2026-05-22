enum Environment { dev, prod }

class AppConfig {
  // Derleme anında dışarıdan geçilen 'ENV' değişkenini okur (varsayılan: dev).
  // Örn: flutter run --dart-define=ENV=prod
  static const String _env = String.fromEnvironment('ENV', defaultValue: 'dev');

  static Environment get environment {
    switch (_env) {
      case 'prod':
        return Environment.prod;
      case 'dev':
      default:
        return Environment.dev;
    }
  }

  static String get baseUrl {
    switch (environment) {
      case Environment.prod:
        return 'https://api.kaviragiyotin.com'; // Canlı sunucu adresi
      case Environment.dev:
      default:
        return 'http://localhost:8000'; // Yerel geliştirme adresi
    }
  }

  static bool get showDebugBanner {
    return environment == Environment.dev;
  }
}