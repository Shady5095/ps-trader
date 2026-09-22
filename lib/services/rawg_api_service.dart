import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/rawg_config.dart';
import '../models/trade_game.dart';

class RawgApiKeyNotConfiguredException implements Exception {
  final String message;
  RawgApiKeyNotConfiguredException([this.message = 'RAWG API key is not configured']);

  @override
  String toString() => message;
}

class RawgApiService {
  final http.Client _client;

  RawgApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Search for games by query string from RAWG API
  Future<List<TradeGame>> searchGames(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return [];

    if (!RawgConfig.isConfigured) {
      throw RawgApiKeyNotConfiguredException(
        'لم يتم ضبط مفتاح RAWG API في RawgConfig.apiKey',
      );
    }

    final uri = Uri.parse(
      '${RawgConfig.baseUrl}/games?key=${RawgConfig.apiKey}&search=${Uri.encodeComponent(trimmedQuery)}&page_size=20',
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List? ?? [];
        return results
            .whereType<Map<String, dynamic>>()
            .map((item) => TradeGame.fromRawgJson(item))
            .where((g) => g.name.isNotEmpty)
            .toList();
      } else {
        throw Exception('فشل في جلب البيانات من RAWG (رمز الحالة: ${response.statusCode})');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الاتصال بخادم RAWG. يرجى التحقق من اتصال الإنترنت.');
    } catch (e) {
      if (e is RawgApiKeyNotConfiguredException) rethrow;
      throw Exception('حدث خطأ أثناء البحث عن الألعاب: $e');
    }
  }
}
