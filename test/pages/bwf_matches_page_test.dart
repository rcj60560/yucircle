import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yucircle/pages/bwf/bwf_matches_page.dart';
import 'package:yucircle/services/bwf_live_service.dart';

// 形状取自 extranet-lv day-matches 实测响应（含国旗/种子/全名）
List<Map<String, dynamic>> _dayMatches() => [
      {
        'code': '176', 'duration': 44,
        'eventName': 'WS', 'roundName': 'R64', 'courtName': 'Court 2',
        'matchTime': '2026-08-18 09:00:00', 'matchStatusValue': 'Finished', 'winner': 2,
        'team1seed': null, 'team2seed': '11',
        'score': [
          {'set': 1, 'home': 21, 'away': 18},
          {'set': 2, 'home': 16, 'away': 21},
          {'set': 3, 'home': 9, 'away': 21},
        ],
        'team1': {
          'countryCode': 'TUR',
          'countryFlagUrl': 'https://img.bwfbadminton.com/flags/TUR.png',
          'players': [
            {'nameShort': 'O BAYRAK', 'nameDisplay': 'Ozgur BAYRAK'},
          ],
        },
        'team2': {
          'countryCode': 'JPN',
          'countryFlagUrl': 'https://img.bwfbadminton.com/flags/JPN.png',
          'players': [
            {'nameShort': 'N OKUHARA', 'nameDisplay': 'Nozomi OKUHARA'},
          ],
        },
      },
      {
        'code': '49', 'duration': null,
        'eventName': 'MS', 'roundName': 'R64', 'courtName': 'Court 2',
        'matchTime': '2026-08-18 10:25:00', 'matchStatusValue': 'none', 'winner': 0,
        'team1seed': null, 'team2seed': null,
        'score': [],
        'team1': {
          'countryCode': 'HKG',
          'players': [
            {'nameShort': 'B YANG'},
          ],
        },
        'team2': {
          'countryCode': 'SGP',
          'players': [
            {'nameShort': 'LOH K Y '},
          ],
        },
      },
    ];

BwfLiveService _fakeService() =>
    BwfLiveService(fetcher: (code, date) async => _dayMatches());

Widget _wrap(BwfMatchesPage page) => MaterialApp(home: page);

void main() {
  testWidgets('当日赛况：场地分组、中文项目、国旗、种子与逐局比分', (tester) async {
    await tester.pumpWidget(_wrap(BwfMatchesPage(
      tournamentName: 'BWF World Championships 2026',
      tournamentCode: 'B671FB97',
      tournamentId: 5601,
      service: _fakeService(),
    )));
    await tester.pump();
    await tester.pump();

    expect(find.text('Court 2'), findsOneWidget);
    // 中文项目徽章 + 轮次
    expect(find.text('女单'), findsOneWidget);
    expect(find.text('男单'), findsOneWidget);
    expect(find.text('R64'), findsNWidgets(2));
    // 国旗图片（已结束场 2 个；未开赛场无 flagUrl → 文字回退）
    expect(find.byType(Image), findsNWidgets(2));
    // 种子号
    expect(find.textContaining('[11]'), findsOneWidget);
    // 状态
    expect(find.text('✓ 已结束'), findsOneWidget);
    expect(find.text('10:25'), findsOneWidget);
    // 逐局比分（3 局：21/18/16/21/9/21）
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('拉取失败显示错误态与重试按钮', (tester) async {
    final service = BwfLiveService(
        fetcher: (code, date) async => throw Exception('network down'));
    await tester.pumpWidget(_wrap(BwfMatchesPage(
        tournamentName: 'x', tournamentCode: 'c', tournamentId: 1, service: service)));
    await tester.pump();
    await tester.pump();

    expect(find.text('拉取当日赛况失败，请检查网络后重试'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });
}
