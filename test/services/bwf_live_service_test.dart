import 'package:flutter_test/flutter_test.dart';
import 'package:yucircle/services/bwf_live_service.dart';

Map<String, dynamic> _raw(String code, String time, String court) => {
      'code': code,
      'eventName': 'MS',
      'roundName': 'R64',
      'courtName': court,
      'matchTime': time,
      'matchStatusValue': 'none',
      'winner': 0,
      'team1': {
        'countryCode': 'INA',
        'players': [
          {'nameShort': 'A'},
        ],
      },
      'team2': {
        'countryCode': 'JPN',
        'players': [
          {'nameShort': 'B'},
        ],
      },
    };

void main() {
  test('保持 API 原序：不按开赛时间重排（官方对阵顺序契约）', () async {
    // API 顺序：553(10:45) 在 49(10:25) 之前 —— not-before 赛制下时间漂移是常态
    final service = BwfLiveService(fetcher: (code, date) async => [
          _raw('553', '2026-08-18 10:45:00', 'Court 2'),
          _raw('49', '2026-08-18 10:25:00', 'Court 2'),
          _raw('176', '2026-08-18 09:00:00', 'Court 1'),
        ]);
    final matches =
        await service.fetchDayMatches('T-CODE', DateTime(2026, 8, 18));
    expect(matches.map((m) => m.matchCode).toList(), ['553', '49', '176']);
  });

  test('fetchMatchStats 走注入口并解析', () async {
    final service = BwfLiveService(statsFetcher: (tmtId, code) async => {
          'info': {'drawName': 'XD', 'roundName': 'R64', 'winner': 2},
          'location': {'locationName': 'Stadium'},
          'progress': {'duration': 33},
          'games': [
            {
              'team1': 16,
              'team2': 21,
              'match_set_details_model': [
                {'ordering': 1, 'team1': 1, 'team2': 0},
              ],
              'match_set_stats_model': {'team1_rallies_won': 16},
            },
          ],
        });
    final stats = await service.fetchMatchStats(5601, '553');
    expect(stats.winner, 2);
    expect(stats.games.first.points.length, 1);
    expect(stats.games.first.team1RalliesWon, 16);
  });
}
