/// BWF 世界排名数据模型（schema 见 docs/superpowers/specs/2026-08-14-bwf-info-design.md §4.2）
class RankingEntry {
  final int rank;
  final int change; // 正=上升 负=下降 0=持平
  final String country;
  final String player; // 双打为 "A / B" 单字符串
  final int points;

  const RankingEntry({
    required this.rank,
    required this.change,
    required this.country,
    required this.player,
    required this.points,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) => RankingEntry(
        rank: (json['rank'] as num).toInt(),
        change: (json['change'] as num? ?? 0).toInt(),
        country: json['country'] as String? ?? '',
        player: json['player'] as String? ?? '',
        points: (json['points'] as num? ?? 0).toInt(),
      );
}

class DisciplineRanking {
  final String key; // ms/ws/md/wd/xd
  final String name; // 男单/女单/男双/女双/混双
  final List<RankingEntry> entries;

  const DisciplineRanking({
    required this.key,
    required this.name,
    required this.entries,
  });

  factory DisciplineRanking.fromJson(String key, Map<String, dynamic> json) =>
      DisciplineRanking(
        key: key,
        name: json['name'] as String? ?? key,
        entries: ((json['entries'] as List?) ?? [])
            .map((e) => RankingEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class RankingsData {
  final DateTime updatedAt;
  final Map<String, DisciplineRanking> disciplines;

  const RankingsData({required this.updatedAt, required this.disciplines});

  factory RankingsData.fromJson(Map<String, dynamic> json) => RankingsData(
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime(2000),
        disciplines: (json['disciplines'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(
              k, DisciplineRanking.fromJson(k, Map<String, dynamic>.from(v as Map))),
        ),
      );
}
