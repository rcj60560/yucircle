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
      'code': '553',
      'duration': 33,
      'eventName': doubles ? 'XD' : 'MS',
      'roundName': 'R64',
      'courtName': 'Court 2',
      'matchTime': '2026-08-18 10:45:00',
      'matchStatusValue': status,
      'winner': winner,
      'team1seed': null,
      'team2seed': '3',
      'score': score,
      'team1': {
        'countryCode': 'MAS',
        'countryFlagUrl':
            'https://img.bwfbadminton.com/image/upload/v2/assets/flag-circle-svg-custom/MAS.png',
        'players': [
          {
            'nameShort': 'WONG T C ',
            'nameDisplay': 'WONG Tien Ci',
            'avatar': {
              'thumbnailUrl':
                  'https://img.bwfbadminton.com/assets/players/thumbnail/71294.jpg'
            },
          },
          if (doubles)
            {
              'nameShort': 'LIM C S ',
              'nameDisplay': 'LIM Chiew Sien',
              'avatar': null,
            },
        ],
      },
      'team2': {
        'countryCode': 'INA',
        'countryFlagUrl': 'https://img.bwfbadminton.com/flags/INA.png',
        'players': [
          {'nameShort': 'KUSHARJANTO', 'nameDisplay': 'Rehan Naufal KUSHARJANTO'},
          if (doubles)
            {
              'nameShort': 'G WIDJAJA',
              'nameDisplay': 'Gloria Emanuelle WIDJAJA',
            },
        ],
      },
    };

void main() {
  test('解析富化字段：国旗/全名/头像/时长/场次码/中文项目', () {
    final m = BwfMatch.fromJson(_match(
      status: 'Finished',
      winner: 2,
      score: [
        {'set': 1, 'home': 16, 'away': 21},
      ],
    ));
    expect(m.matchCode, '553');
    expect(m.durationMin, 33);
    expect(m.eventNameZh, '男单');
    expect(m.team1.countryCode, 'MAS');
    expect(m.team1.flagUrl, contains('MAS.png'));
    expect(m.team1.players.first.nameDisplay, 'WONG Tien Ci');
    expect(m.team1.players.first.nameShort, 'WONG T C ');
    expect(m.team1.players.first.avatarUrl, contains('71294'));
    // 无 avatar 字段 → null（不崩）
    expect(m.team2.players.first.avatarUrl, isNull);
    expect(m.winner, 2);
    expect(m.sets.first.away, 21);
  });

  test('解析进行中与未开始：状态枚举与 duration 缺省', () {
    final live = BwfMatch.fromJson(_match(status: 'In Progress'));
    expect(live.status, BwfMatchStatus.inProgress);
    expect(live.durationMin, 33);
    final map = _match(status: 'none')..remove('duration');
    final upcoming = BwfMatch.fromJson(map);
    expect(upcoming.status, BwfMatchStatus.upcoming);
    expect(upcoming.durationMin, isNull);
  });

  test('双打拼接两名球员（短名/全名）与混双中文', () {
    final m = BwfMatch.fromJson(_match(doubles: true));
    expect(m.team1.display, 'WONG T C / LIM C S');
    expect(m.team2.displayFull, 'Rehan Naufal KUSHARJANTO / Gloria Emanuelle WIDJAJA');
    expect(m.eventNameZh, '混双');
  });

  test('nameDisplay 缺失回退 nameShort', () {
    final map = _match();
    (map['team2'] as Map)['players'] = [
      {'nameShort': 'J CHRISTIE'},
    ];
    final m = BwfMatch.fromJson(map);
    expect(m.team2.players.first.nameDisplay, 'J CHRISTIE');
  });
}
