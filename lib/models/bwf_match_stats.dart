// 单场逐分统计（extranet-lv /api/h2h/match?tmt_id=&match_code=）；实时数据不落库

/// 一分的归属（team1/team2 二选一为 1）
class GamePoint {
  final int team1;
  final int team2;

  const GamePoint({required this.team1, required this.team2});

  factory GamePoint.fromJson(Map<String, dynamic> json) => GamePoint(
        team1: (json['team1'] as num? ?? 0).toInt(),
        team2: (json['team2'] as num? ?? 0).toInt(),
      );
}

class BwfGameStats {
  final int team1Score; // 该局终分
  final int team2Score;
  final List<GamePoint> points; // 逐分序列（按 ordering 升序）
  final int? team1RalliesWon; // 局内得分
  final int? team2RalliesWon;
  final int? team1Consecutive; // 局内最高连续得分
  final int? team2Consecutive;

  const BwfGameStats({
    required this.team1Score,
    required this.team2Score,
    required this.points,
    this.team1RalliesWon,
    this.team2RalliesWon,
    this.team1Consecutive,
    this.team2Consecutive,
  });

  factory BwfGameStats.fromJson(Map<String, dynamic> json) {
    final stats =
        Map<String, dynamic>.from(json['match_set_stats_model'] as Map? ?? {});
    int? val(String k) => (stats[k] as num?)?.toInt();
    final points = ((json['match_set_details_model'] as List?) ?? [])
        .map((p) => Map<String, dynamic>.from(p as Map))
        .toList();
    points.sort((a, b) =>
        ((a['ordering'] as num?) ?? 0).compareTo((b['ordering'] as num?) ?? 0));
    return BwfGameStats(
      team1Score: (json['team1'] as num? ?? 0).toInt(),
      team2Score: (json['team2'] as num? ?? 0).toInt(),
      points: points.map((p) => GamePoint.fromJson(p)).toList(),
      team1RalliesWon: val('team1_rallies_won'),
      team2RalliesWon: val('team2_rallies_won'),
      team1Consecutive: val('team1_consecutive_points'),
      team2Consecutive: val('team2_consecutive_points'),
    );
  }
}

class BwfMatchStats {
  final String location;
  final int? durationMin;
  final String? roundName;
  final String? drawName; // 项目码 MS/XD…
  final int winner; // 1/2，0 = 未定
  final List<BwfGameStats> games;

  const BwfMatchStats({
    required this.location,
    required this.durationMin,
    required this.roundName,
    required this.drawName,
    required this.winner,
    required this.games,
  });

  factory BwfMatchStats.fromJson(Map<String, dynamic> json) => BwfMatchStats(
        location:
            (json['location'] as Map?)?['locationName'] as String? ?? '',
        durationMin: ((json['progress'] as Map?)?['duration'] as num?)?.toInt(),
        roundName: (json['info'] as Map?)?['roundName'] as String?,
        drawName: (json['info'] as Map?)?['drawName'] as String?,
        winner: ((json['info'] as Map?)?['winner'] as num? ?? 0).toInt(),
        games: ((json['games'] as List?) ?? [])
            .map((g) => BwfGameStats.fromJson(Map<String, dynamic>.from(g as Map)))
            .toList(),
      );
}
