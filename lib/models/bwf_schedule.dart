/// BWF 世界巡回赛赛程模型；状态由日期推导，不落库
enum TournamentLevel { super1000, super750, super500, super300, finals, other }

enum TournamentStatus { completed, ongoing, upcoming }

class Tournament {
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String city;
  final TournamentLevel level;
  final int prizeMoney; // 0 = 未知（UI 不显示）

  const Tournament({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.city,
    required this.level,
    required this.prizeMoney,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
        name: json['name'] as String? ?? '',
        startDate:
            DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime(2000),
        endDate: DateTime.tryParse(json['endDate'] as String? ?? '') ?? DateTime(2000),
        city: json['city'] as String? ?? '',
        level: _levelFrom(json['level'] as String? ?? 'other'),
        prizeMoney: (json['prizeMoney'] as num? ?? 0).toInt(),
      );

  static TournamentLevel _levelFrom(String s) {
    switch (s) {
      case 'super1000':
        return TournamentLevel.super1000;
      case 'super750':
        return TournamentLevel.super750;
      case 'super500':
        return TournamentLevel.super500;
      case 'super300':
        return TournamentLevel.super300;
      case 'finals':
        return TournamentLevel.finals;
      default:
        return TournamentLevel.other;
    }
  }

  /// endDate < 今天 → completed；start~end 区间内 → ongoing；否则 upcoming
  TournamentStatus statusOn(DateTime today) {
    final d = DateTime(today.year, today.month, today.day);
    if (d.isAfter(endDate)) return TournamentStatus.completed;
    if (d.isBefore(startDate)) return TournamentStatus.upcoming;
    return TournamentStatus.ongoing;
  }
}

class ScheduleData {
  final int year;
  final DateTime updatedAt;
  final List<Tournament> tournaments; // 已按 startDate 升序（爬虫侧保证）

  const ScheduleData({
    required this.year,
    required this.updatedAt,
    required this.tournaments,
  });

  factory ScheduleData.fromJson(Map<String, dynamic> json) => ScheduleData(
        year: (json['year'] as num? ?? 0).toInt(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime(2000),
        tournaments: ((json['tournaments'] as List?) ?? [])
            .map((t) => Tournament.fromJson(Map<String, dynamic>.from(t as Map)))
            .toList(),
      );
}
