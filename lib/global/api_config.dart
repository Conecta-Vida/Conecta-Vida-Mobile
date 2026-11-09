import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Resolve a URL base da API exclusiva do aplicativo cidadão.
///
/// Prioridade:
/// 1. --dart-define=API_BASE_URL=...
/// 2. API_BASE_URL em assets/config/app.env
/// 3. Padrão por plataforma:
///    - Android Emulator: http://10.0.2.2:8081/api
///    - Flutter Web: /api (mesma origem; o proxy encaminha para a mobile-api)
///    - iOS simulator / desktop: http://localhost:8081/api
class ApiConfig {
  static const String _definidaNoBuild = String.fromEnvironment('API_BASE_URL');

  static String resolverBaseUrl() {
    if (_definidaNoBuild.isNotEmpty) {
      return _semBarraFinal(_definidaNoBuild);
    }

    final doEnv = dotenv.isInitialized
        ? dotenv.env['API_BASE_URL']?.trim()
        : null;
    if (doEnv != null && doEnv.isNotEmpty) {
      return _semBarraFinal(doEnv);
    }

    if (kIsWeb) return '/api';

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8081/api';
    }

    return 'http://localhost:8081/api';
  }

  static String _semBarraFinal(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
