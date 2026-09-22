import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ps_trades_app/models/trade.dart';
import 'package:ps_trades_app/models/trade_game.dart';
import 'package:ps_trades_app/services/rawg_api_service.dart';

void main() {
  group('TradeGame Model Tests', () {
    test('toMap and fromMap work properly', () {
      const game = TradeGame(
        id: '3498',
        name: 'Grand Theft Auto V',
        coverUrl: 'https://media.rawg.io/media/games/456/456dea5e1c7e3cd070250266b82a69ac.jpg',
        releaseYear: '2013',
        platforms: 'PlayStation 5, PlayStation 4',
        source: 'rawg',
      );

      final map = game.toMap();
      expect(map['id'], equals('3498'));
      expect(map['name'], equals('Grand Theft Auto V'));
      expect(map['releaseYear'], equals('2013'));
      expect(map['platforms'], equals('PlayStation 5, PlayStation 4'));

      final fromMap = TradeGame.fromMap(map);
      expect(fromMap.id, equals(game.id));
      expect(fromMap.name, equals(game.name));
      expect(fromMap.coverUrl, equals(game.coverUrl));
      expect(fromMap.releaseYear, equals(game.releaseYear));
      expect(fromMap.platforms, equals(game.platforms));
      expect(fromMap.source, equals('rawg'));
    });

    test('fromRawgJson parses API response accurately', () {
      final rawgJson = {
        'id': 4200,
        'name': 'Portal 2',
        'background_image': 'https://media.rawg.io/media/games/328/3283613cb7d75d67257fc58339188742.jpg',
        'released': '2011-04-18',
        'platforms': [
          {'platform': {'name': 'PlayStation 3'}},
          {'platform': {'name': 'PC'}},
          {'platform': {'name': 'Xbox 360'}},
        ],
      };

      final game = TradeGame.fromRawgJson(rawgJson);
      expect(game.id, equals('4200'));
      expect(game.name, equals('Portal 2'));
      expect(game.coverUrl, contains('3283613cb7d75d67257fc58339188742.jpg'));
      expect(game.releaseYear, equals('2011'));
      expect(game.platforms, equals('PlayStation 3, PC, Xbox 360'));
    });

    test('equality checks are case-insensitive by game name', () {
      const g1 = TradeGame(id: '1', name: 'Spider-Man', coverUrl: 'http://img1.jpg');
      const g2 = TradeGame(id: '99', name: 'spider-man', coverUrl: 'http://img2.jpg');
      const g3 = TradeGame(id: '2', name: 'God of War', coverUrl: 'http://img3.jpg');

      expect(g1 == g2, isTrue);
      expect(g1 == g3, isFalse);
    });
  });

  group('Trade Model with TradeGame list', () {
    test('Trade serialization preserves games list', () {
      final trade = Trade(
        id: 't-test',
        deviceType: 'PS5 Digital',
        controllers: 2,
        gamesCount: 2,
        purchaseDate: DateTime(2026, 1, 1),
        purchasePrice: 15000,
        sellerNumber: '01000000000',
        sellerLocation: 'Cairo',
        gamesIncluded: 'FIFA 24, Horizon',
        notes: 'Good condition',
        status: TradeStatus.inStock,
        games: const [
          TradeGame(id: '1', name: 'FIFA 24', coverUrl: 'https://img/fifa.jpg'),
          TradeGame(id: '2', name: 'Horizon Forbidden West', coverUrl: 'https://img/hfw.jpg'),
        ],
      );

      final map = trade.toMap();
      expect(map['games'], isA<List>());
      expect((map['games'] as List).length, equals(2));

      final fromMap = Trade.fromMap(map);
      expect(fromMap.games.length, equals(2));
      expect(fromMap.games.first.name, equals('FIFA 24'));
      expect(fromMap.games.last.name, equals('Horizon Forbidden West'));
    });

    test('Trade.copyWith updates games list properly', () {
      final trade = Trade(
        id: 't-copy',
        deviceType: 'PS4 Pro',
        controllers: 1,
        gamesCount: 0,
        purchaseDate: DateTime(2026, 2, 1),
        purchasePrice: 8000,
        sellerNumber: '01111111111',
        sellerLocation: 'Alex',
        gamesIncluded: '',
        notes: '',
        status: TradeStatus.inStock,
      );

      expect(trade.games, isEmpty);

      final updated = trade.copyWith(
        games: const [
          TradeGame(id: '10', name: 'Bloodborne', coverUrl: 'https://img/bb.jpg'),
        ],
      );

      expect(updated.games.length, equals(1));
      expect(updated.games.first.name, equals('Bloodborne'));
    });

    test('Trade handles conditionRating serialization, copyWith, and defaults', () {
      final defaultTrade = Trade(
        id: 't-def',
        deviceType: 'PS5',
        controllers: 2,
        gamesCount: 0,
        purchaseDate: DateTime(2026, 1, 1),
        purchasePrice: 10000,
        sellerNumber: '010',
        sellerLocation: 'Loc',
        gamesIncluded: '',
        notes: '',
        status: TradeStatus.inStock,
      );
      expect(defaultTrade.conditionRating, equals(3));

      final customTrade = defaultTrade.copyWith(conditionRating: 2);
      expect(customTrade.conditionRating, equals(2));

      final map = customTrade.toMap();
      expect(map['conditionRating'], equals(2));

      final fromMap = Trade.fromMap(map);
      expect(fromMap.conditionRating, equals(2));

      // Legacy map without conditionRating defaults to 3
      final legacyMap = {'id': 'legacy', 'deviceType': 'PS4'};
      final fromLegacy = Trade.fromMap(legacyMap);
      expect(fromLegacy.conditionRating, equals(3));
    });
  });

  group('RawgApiService Tests', () {
    test('searchGames returns empty list for empty query', () async {
      final service = RawgApiService();
      final results = await service.searchGames('   ');
      expect(results, isEmpty);
    });

    test('searchGames parses mock response correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/games')) {
          final responseData = {
            'results': [
              {
                'id': 1001,
                'name': 'God of War Ragnarök',
                'background_image': 'https://media.rawg.io/gow.jpg',
                'released': '2022-11-09',
                'platforms': [
                  {'platform': {'name': 'PlayStation 5'}},
                  {'platform': {'name': 'PlayStation 4'}},
                ],
              },
            ],
          };
          return http.Response(jsonEncode(responseData), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = RawgApiService(client: mockClient);
      final results = await service.searchGames('God of War');
      expect(results.length, equals(1));
      expect(results.first.name, equals('God of War Ragnarök'));
      expect(results.first.releaseYear, equals('2022'));
      expect(results.first.platforms, equals('PlayStation 5, PlayStation 4'));
    });
  });
}
