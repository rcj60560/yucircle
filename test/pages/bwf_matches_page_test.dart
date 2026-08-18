import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yucircle/pages/bwf/bwf_matches_page.dart';
import 'package:yucircle/services/bwf_live_service.dart';

// 形状取自 extranet-lv day-matches 实测响应
List<Map<String, dynamic>> _dayMatches() => [
      {
        'eventName': 'MS', 'roundName': 'R64', 'courtName': 'Court 1',
        'matchTime': '2026-08-18 09:00:00', 'matchStatusValue': 'Finished', 'winner': 2,
        'team1seed': null, 'team2seed': '3',
        'score': [
          {'set': 1, 'home': 15, 'away': 21},
          {'set': 2, 'home': 14, 'away': 21},
        ],
        'team1': {
          'countryCode': 'GER',
          'players': [
            {'nameShort': 'M KICKLITZ'},
          ],
        },
        'team2': {
          'countryCode': 'INA',
          'players': [
            {'nameShort': 'J CHRISTIE'},
          ],
        },
      },
      {
        'eventName': 'WS', 'roundName': 'R64', 'courtName': 'Court 2',
        'matchTime': '2026-08-18 13:00:00', 'matchStatusValue': 'none', 'winner': 0,
        'team1seed': '4', 'team2seed': null,
        'score': [],
        'team1': {
          'countryCode': 'JPN',
          'players': [
            {'nameShort': 'N OKUHARA'},
          ],
        },
        'team2': {
          'countryCode': 'TUR',
          'players': [
            {'nameShort': 'O BAYRAK'},
          ],
        },
      },
    ];

BwfLiveService _fakeService() =>
    BwfLiveService(fetcher: (code, date) async => _dayMatches());

void main() {
  testWidgets('当日赛况：按场地分组、状态与逐局比分渲染', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BwfMatchesPage(
        tournamentName: 'BWF World Championships 2026',
        tournamentCode: 'B671FB97',
        service: _fakeService(),
      ),
    ));
    await tester.pump(); // FutureBuilder 数据到达
    await tester.pump();

    // 场地分组标题
    expect(find.text('Court 1'), findsOneWidget);
    expect(find.text('Court 2'), findsOneWidget);
    // 对阵双方（Text.rich 拼接了国家/种子，用包含匹配）
    expect(find.textContaining('M KICKLITZ'), findsOneWidget);
    expect(find.textContaining('J CHRISTIE'), findsOneWidget);
    // 状态：已结束 / 开赛时间（13:00）
    expect(find.text('✓ 已结束'), findsOneWidget);
    expect(find.text('13:00'), findsOneWidget);
    // 项目与轮次徽章
    expect(find.text('MS'), findsOneWidget);
    expect(find.text('R64'), findsNWidgets(2));
    // 逐局比分：team1 两局 15/14，team2 两局 21/21
    expect(find.text('15'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(find.text('21'), findsNWidgets(2));
  });

  testWidgets('拉取失败显示错误态与重试按钮', (tester) async {
    final service = BwfLiveService(
        fetcher: (code, date) async => throw Exception('network down'));
    await tester.pumpWidget(MaterialApp(
      home: BwfMatchesPage(
          tournamentName: 'x', tournamentCode: 'c', service: service),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('拉取当日赛况失败，请检查网络后重试'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });
}
