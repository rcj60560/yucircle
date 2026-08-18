/// 当日对阵模型（extranet-lv day-matches API）；实时数据不落库，仅内存展示
enum BwfMatchStatus { finished, inProgress, upcoming }

class BwfMatchTeam {
  final List<String> players; // nameShort；双打两项
  final String countryCode;
  final String? seed;

  const BwfMatchTeam({required this.players, required this.countryCode, this.seed});

  String get display => players.join(' / ');

  factory BwfMatchTeam.fromJson(Map<String, dynamic> json, {String? seed}) =>
      BwfMatchTeam(
        players: ((json['players'] as List?) ?? [])
            .map((p) => (p as Map)['nameShort'] as String? ?? '')
            .where((s) => s.isNotEmpty)
            .toList(),
        countryCode: json['countryCode'] as String? ?? '',
        seed: seed,
      );
}

class BwfMatchSet {
  final int home; // team1 得分
  final int away; // team2 得分

  const BwfMatchSet({required this.home, required this.away});

  factory BwfMatchSet.fromJson(Map<String, dynamic> json) => BwfMatchSet(
        home: (json['home'] as num? ?? 0).toInt(),
        away: (json['away'] as num? ?? 0).toInt(),
      );
}

class BwfMatch {
  final String eventName; // MS/WS/MD/WD/XD
  final String roundName; // R64/QF/SF/F…
  final String courtName;
  final DateTime matchTime;
  final BwfMatchStatus status;
  final int winner; // 1/2，0 = 未定
  final BwfMatchTeam team1;
  final BwfMatchTeam team2;
  final List<BwfMatchSet> sets;

  const BwfMatch({
    required this.eventName,
    required this.roundName,
    required this.courtName,
    required this.matchTime,
    required this.status,
    required this.winner,
    required this.team1,
    required this.team2,
    required this.sets,
  });

  factory BwfMatch.fromJson(Map<String, dynamic> json) {
    final statusStr = json['matchStatusValue'] as String? ?? '';
    return BwfMatch(
      eventName: json['eventName'] as String? ?? '',
      roundName: json['roundName'] as String? ?? '',
      courtName: json['courtName'] as String? ?? '',
      matchTime:
          DateTime.tryParse(json['matchTime'] as String? ?? '') ?? DateTime(2000),
      status: switch (statusStr) {
        'Finished' => BwfMatchStatus.finished,
        'In Progress' => BwfMatchStatus.inProgress,
        _ => BwfMatchStatus.upcoming,
      },
      winner: (json['winner'] as num? ?? 0).toInt(),
      team1: BwfMatchTeam.fromJson(
          Map<String, dynamic>.from(json['team1'] as Map? ?? {}),
          seed: json['team1seed'] as String?),
      team2: BwfMatchTeam.fromJson(
          Map<String, dynamic>.from(json['team2'] as Map? ?? {}),
          seed: json['team2seed'] as String?),
      sets: ((json['score'] as List?) ?? [])
          .map((s) => BwfMatchSet.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList(),
    );
  }
}
