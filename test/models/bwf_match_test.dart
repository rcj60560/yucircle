import 'package:flutter_test/flutter_test.dart';
import 'package:yucircle/models/bwf_match.dart';

// 形状取自 extranet-lv day-matches 实测响应（2026-08-18 世锦赛）
Map<String, dynamic> _match({
  String status = 'Finished',
  int winner = 0,
  List<Map<String, dynamic>> score = const [],
  bool doubles = false,
}) =>
    {
      'eventName': doubles ? 'MD' : 'MS',
      'roundName': 'R64',
      'courtName': 'Court 1',
      'matchTime': '2026-08-18 09:00:00',
      'matchStatusValue': status,
      'winner': winner,
      'team1seed': null,
      'team2seed': '3',
      'score': score,
      'team1': {
        'countryCode': 'GER',
        'players': [
          {'nameShort': 'M KICKLITZ', 'countryCode': 'GER'},
          if (doubles) {'nameShort': 'R BECK', 'countryCode': 'GER'},
        ],
      },
      'team2': {
        'countryCode': 'INA',
        'players': [
          {'nameShort': 'J CHRISTIE', 'countryCode': 'INA'},
          if (doubles) {'nameShort': 'F ALFIAN', 'countryCode': 'INA'},
        ],
      },
    };

void main() {
  test('解析已结束单打：状态/胜方/逐局比分', () {
    final m = BwfMatch.fromJson(_match(
      status: 'Finished',
      winner: 2,
      score: [
        {'set': 1, 'home': 15, 'away': 21},
        {'set': 2, 'home': 14, 'away': 21},
      ],
    ));
    expect(m.status, BwfMatchStatus.finished);
    expect(m.winner, 2);
    expect(m.eventName, 'MS');
    expect(m.roundName, 'R64');
    expect(m.courtName, 'Court 1');
    expect(m.matchTime, DateTime(2026, 8, 18, 9, 0));
    expect(m.team1.display, 'M KICKLITZ');
    expect(m.team1.countryCode, 'GER');
    expect(m.team2.seed, '3');
    expect(m.sets.length, 2);
    expect(m.sets[0].home, 15);
    expect(m.sets[1].away, 21);
  });

  test('解析进行中与未开始：状态枚举映射', () {
    expect(BwfMatch.fromJson(_match(status: 'In Progress')).status,
        BwfMatchStatus.inProgress);
    expect(BwfMatch.fromJson(_match(status: 'none')).status,
        BwfMatchStatus.upcoming);
  });

  test('双打拼接两名球员', () {
    final m = BwfMatch.fromJson(_match(doubles: true));
    expect(m.team1.display, 'M KICKLITZ / R BECK');
    expect(m.team2.display, 'J CHRISTIE / F ALFIAN');
  });
}
