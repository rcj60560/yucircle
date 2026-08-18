/// 当日对阵模型（extranet-lv day-matches API）；实时数据不落库，仅内存展示
enum BwfMatchStatus { finished, inProgress, upcoming }

/// 项目英文码 → 中文
const eventNamesZh = {
  'MS': '男单', 'WS': '女单', 'MD': '男双', 'WD': '女双', 'XD': '混双',
};

class BwfMatchPlayer {
  final String nameShort; // "G WIDJAJA"
  final String nameDisplay; // "Gloria Emanuelle WIDJAJA"（缺省回退 nameShort）
  final String? avatarUrl; // 头像缩略图（可能缺）

  const BwfMatchPlayer(
      {required this.nameShort, required this.nameDisplay, this.avatarUrl});

  factory BwfMatchPlayer.fromJson(Map<String, dynamic> json) {
    final short = json['nameShort'] as String? ?? '';
    return BwfMatchPlayer(
      nameShort: short,
      nameDisplay: (json['nameDisplay'] as String?)?.trim().isNotEmpty == true
          ? json['nameDisplay'] as String
          : short,
      avatarUrl: (json['avatar'] as Map?)?['thumbnailUrl'] as String?,
    );
  }
}

class BwfMatchTeam {
  final List<BwfMatchPlayer> players; // 双打两项
  final String countryCode;
  final String? flagUrl; // 圆形国旗 PNG（CDN）
  final String? seed;

  const BwfMatchTeam(
      {required this.players, required this.countryCode, this.flagUrl, this.seed});

  String get display => players.map((p) => p.nameShort.trim()).join(' / ');
  String get displayFull =>
      players.map((p) => p.nameDisplay.trim()).join(' / ');

  factory BwfMatchTeam.fromJson(Map<String, dynamic> json, {String? seed}) =>
      BwfMatchTeam(
        players: ((json['players'] as List?) ?? [])
            .map((p) =>
                BwfMatchPlayer.fromJson(Map<String, dynamic>.from(p as Map)))
            .toList(),
        countryCode: json['countryCode'] as String? ?? '',
        flagUrl: json['countryFlagUrl'] as String?,
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
  final String matchCode; // 场次码（详情 h2h API 用）
  final String eventName; // MS/WS/MD/WD/XD
  final String roundName; // R64/QF/SF/F…
  final String courtName;
  final DateTime matchTime;
  final BwfMatchStatus status;
  final int winner; // 1/2，0 = 未定
  final int? durationMin; // 时长（分钟，可能缺）
  final BwfMatchTeam team1;
  final BwfMatchTeam team2;
  final List<BwfMatchSet> sets;

  const BwfMatch({
    required this.matchCode,
    required this.eventName,
    required this.roundName,
    required this.courtName,
    required this.matchTime,
    required this.status,
    required this.winner,
    required this.team1,
    required this.team2,
    required this.sets,
    this.durationMin,
  });

  String get eventNameZh => eventNamesZh[eventName] ?? eventName;

  factory BwfMatch.fromJson(Map<String, dynamic> json) {
    final statusStr = json['matchStatusValue'] as String? ?? '';
    return BwfMatch(
      matchCode: json['code'] as String? ?? '',
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
      durationMin: (json['duration'] as num?)?.toInt(),
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
