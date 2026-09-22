import 'dart:convert';

/// Represents a single PlayStation game associated with a trade device
class TradeGame {
  final String id;
  final String name;
  final String coverUrl;
  final String? releaseYear;
  final String? platforms;
  final String source;

  const TradeGame({
    required this.id,
    required this.name,
    required this.coverUrl,
    this.releaseYear,
    this.platforms,
    this.source = 'rawg',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'coverUrl': coverUrl,
      if (releaseYear != null && releaseYear!.isNotEmpty)
        'releaseYear': releaseYear,
      if (platforms != null && platforms!.isNotEmpty) 'platforms': platforms,
      'source': source,
    };
  }

  factory TradeGame.fromMap(Map<String, dynamic> map) {
    return TradeGame(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      coverUrl: map['coverUrl']?.toString() ?? '',
      releaseYear: map['releaseYear']?.toString(),
      platforms: map['platforms']?.toString(),
      source: map['source']?.toString() ?? 'rawg',
    );
  }

  factory TradeGame.fromRawgJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    final cover = json['background_image']?.toString() ?? '';
    final released = json['released']?.toString() ?? '';
    final year = released.length >= 4 ? released.substring(0, 4) : null;

    String? platformStr;
    if (json['platforms'] is List) {
      final pList = (json['platforms'] as List)
          .map((p) => p['platform']?['name']?.toString())
          .whereType<String>()
          .take(3)
          .join(', ');
      if (pList.isNotEmpty) platformStr = pList;
    }

    return TradeGame(
      id: id,
      name: name,
      coverUrl: cover,
      releaseYear: year,
      platforms: platformStr,
      source: 'rawg',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory TradeGame.fromJson(String source) =>
      TradeGame.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TradeGame &&
        other.name.trim().toLowerCase() == name.trim().toLowerCase();
  }

  @override
  int get hashCode => name.trim().toLowerCase().hashCode;
}
