import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
  }

  static String get apiBaseUrl => dotenv.get('API_BASE_URL', fallback: 'https://api.fixen.com/api/v1');
  static String get socketUrl => dotenv.get('SOCKET_URL', fallback: 'https://api.fixen.com');
  static String get googleMapsApiKey => dotenv.get('GOOGLE_MAPS_API_KEY', fallback: '');
  static String get environment => dotenv.get('ENVIRONMENT', fallback: 'production');
  
  static bool get isProduction => environment == 'production';
}
