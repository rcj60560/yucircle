import 'package:flutter_test/flutter_test.dart';
import 'package:yucircle/models/bwf_ranking.dart';
import 'package:yucircle/models/bwf_schedule.dart';

void main() {
  test('RankingsData.fromJson 解析与双打拼接', () {
    final data = RankingsData.fromJson({
      'updatedAt': '2026-08-14T09:00:00+08:00',
      'disciplines': {
        'ms': {
          'name': '男单',
          'entries': [
            {'rank': 1, 'change': 0, 'country': 'TPE', 'player': 'CHOU Tien Chen', 'points': 67710},
          ],
        },
        'xd': {
          'name': '混双',
          'entries': [
            {'rank': 1, 'change': -2, 'country': 'TPE', 'player': 'WANG Chi-Lin / LEE Jhe-Huei', 'points': 70000},
          ],
        },
      },
    });
    expect(data.disciplines.length, 2);
    final ms = data.disciplines['ms']!;
    expect(ms.name, '男单');
    expect(ms.entries.first.player, 'CHOU Tien Chen');
    expect(ms.entries.first.points, 67710);
    expect(data.disciplines['xd']!.entries.first.change, -2);
  });

  test('Tournament.level 映射与 statusOn 边界', () {
    final t = Tournament.fromJson({
      'name': 'LI-NING China Masters 2026',
      'startDate': '2026-09-01',
      'endDate': '2026-09-06',
      'city': 'Shenzhen',
      'level': 'super750',
      'prizeMoney': 1150000,
    });
    expect(t.level, TournamentLevel.super750);
    expect(t.prizeMoney, 1150000);
    expect(t.statusOn(DateTime(2026, 8, 31)), TournamentStatus.upcoming);
    expect(t.statusOn(DateTime(2026, 9, 1)), TournamentStatus.ongoing);
    expect(t.statusOn(DateTime(2026, 9, 6)), TournamentStatus.ongoing);
    expect(t.statusOn(DateTime(2026, 9, 7)), TournamentStatus.completed);
  });

  test('Tournament.level major 映射（世锦赛/汤尤杯）', () {
    final t = Tournament.fromJson({
      'name': 'BWF World Championships 2026',
      'startDate': '2026-08-17',
      'endDate': '2026-08-23',
      'city': 'New Delhi, India',
      'level': 'major',
      'prizeMoney': 0,
      'code': 'B671FB97-491C-46D3-982F-56525168C3AA',
      'hasLiveScores': true,
    });
    expect(t.level, TournamentLevel.major);
    expect(t.code, 'B671FB97-491C-46D3-982F-56525168C3AA');
    expect(t.hasLiveScores, isTrue);
  });

  test('Tournament 旧资产无 code/hasLiveScores 字段时向后兼容', () {
    final t = Tournament.fromJson({
      'name': 'x',
      'startDate': '2026-01-01',
      'endDate': '2026-01-02',
      'city': '',
      'level': 'super300',
      'prizeMoney': 0,
    });
    expect(t.code, isNull);
    expect(t.hasLiveScores, isFalse);
  });

  test('ScheduleData.fromJson 未知 level 归为 other', () {
    final s = ScheduleData.fromJson({
      'year': 2026,
      'tournaments': [
        {'name': 'x', 'startDate': '2026-01-01', 'endDate': '2026-01-02', 'city': '', 'level': 'whatever', 'prizeMoney': 0},
      ],
    });
    expect(s.year, 2026);
    expect(s.tournaments.first.level, TournamentLevel.other);
  });
}
