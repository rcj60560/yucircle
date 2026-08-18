import 'package:flutter_test/flutter_test.dart';
import 'package:yucircle/models/bwf_match_stats.dart';

// 形状取自 /api/h2h/match 实测响应（世锦赛 553 场，XD 首局 16-21）
Map<String, dynamic> _h2h() => {
      'info': {'drawName': 'XD', 'roundName': 'R64', 'winner': 2},
      'location': {'locationName': 'Indra Gandhi Indoor Stadium'},
      'progress': {'duration': 33},
      'games': [
        {
          'id': 58443684,
          'team1': 16,
          'team2': 21,
          'ordering': 1,
          'match_set_details_model': [
            // 故意乱序 + 双方交替，验证按 ordering 排序后累加成 1-0/1-1/2-1/2-2
            {'ordering': 2, 'team1': 0, 'team2': 1},
            {'ordering': 1, 'team1': 1, 'team2': 0},
            {'ordering': 4, 'team1': 0, 'team2': 1},
            {'ordering': 3, 'team1': 1, 'team2': 0},
          ],
          'match_set_stats_model': {
            'team1_rallies_won': 16,
            'team2_rallies_won': 21,
            'team1_consecutive_points': 4,
            'team2_consecutive_points': 6,
          },
        },
        {
          'id': 58443685,
          'team1': 19,
          'team2': 21,
          'ordering': 2,
          'match_set_details_model': [],
          'match_set_stats_model': {},
        },
      ],
    };

void main() {
  test('解析逐分序列：按 ordering 升序且归属正确', () {
    final stats = BwfMatchStats.fromJson(_h2h());
    final g1 = stats.games.first;
    expect(g1.team1Score, 16);
    expect(g1.team2Score, 21);
    expect(g1.points.length, 4);
    // 乱序输入 → 按 ordering 排序：第1分 team1、第2分 team2…
    expect(g1.points[0].team1, 1);
    expect(g1.points[1].team2, 1);
    expect(g1.points[2].team1, 1);
    expect(g1.points[3].team2, 1);
    // 累加与逐分归属一致（fixture 截取 4 分：team1 得 2 分）
    expect(g1.points.map((p) => p.team1).reduce((a, b) => a + b), 2);
  });

  test('解析统计与元信息；空字段容错', () {
    final stats = BwfMatchStats.fromJson(_h2h());
    expect(stats.location, 'Indra Gandhi Indoor Stadium');
    expect(stats.durationMin, 33);
    expect(stats.roundName, 'R64');
    expect(stats.drawName, 'XD');
    expect(stats.winner, 2);
    final g2 = stats.games[1];
    expect(g2.points, isEmpty);
    expect(g2.team1RalliesWon, isNull); // 空统计 → null 不崩
    expect(g2.team1Consecutive, isNull);
  });
}
