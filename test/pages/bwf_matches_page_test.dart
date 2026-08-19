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

Widget _wrap(BwfMatchesPage page) => MaterialApp(home: page);

void main() {
  testWidgets('当日赛况：场地分组、中文项目、国旗、种子与逐局比分', (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(_wrap(BwfMatchesPage(
      tournamentName: 'BWF World Championships 2026',
      tournamentCode: 'B671FB97',
      tournamentId: 5601,
      rangeStart: DateTime(now.year, now.month, now.day - 2),
      rangeEnd: DateTime(now.year, now.month, now.day + 4),
      service: BwfLiveService(fetcher: (code, date) async => _dayMatches()),
    )));
    await tester.pump();
    await tester.pump();

    expect(find.text('Court 2'), findsOneWidget);
    // 中文项目徽章 + 轮次（女单/男单各 2 处：筛选 chip + 卡片徽章）
    expect(find.text('女单'), findsNWidgets(2));
    expect(find.text('男单'), findsNWidgets(2));
    expect(find.text('R64'), findsNWidgets(2));
    // 国旗图片（已结束场 2 个；未开赛场无 flagUrl → 文字回退）
    expect(find.byType(Image), findsNWidgets(2));
    // 种子号
    expect(find.textContaining('[11]'), findsOneWidget);
    // 状态
    expect(find.text('✓ 已结束'), findsOneWidget);
    expect(find.text('10:25'), findsOneWidget);
    // 逐局比分（3 局）
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('日期条：默认今天，切换日期按所选日期重拉', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final calls = <String>[];
    await tester.pumpWidget(_wrap(BwfMatchesPage(
      tournamentName: '世锦赛',
      tournamentCode: 'c',
      tournamentId: 1,
      rangeStart: DateTime(now.year, now.month, now.day - 2),
      rangeEnd: DateTime(now.year, now.month, now.day + 4),
      service: BwfLiveService(fetcher: (code, date) async {
        calls.add(date);
        return _dayMatches();
      }),
    )));
    await tester.pump();
    await tester.pump();

    // 默认选中今天
    expect(find.text('今天'), findsOneWidget);
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    expect(calls.last, todayStr);
    // 点昨天 chip → 以昨天日期重拉（.first：日期条在比分数字之前渲染，避免与比分"18"混淆）
    await tester.tap(find.text('${yesterday.day}').first);
    await tester.pump();
    await tester.pump();
    final yStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    expect(calls.last, yStr);
    expect(calls.length, 2);
  });

  testWidgets('筛选：状态过滤隐藏未开赛场次，项目过滤只留所选项目', (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(_wrap(BwfMatchesPage(
      tournamentName: '世锦赛',
      tournamentCode: 'c',
      tournamentId: 1,
      rangeStart: DateTime(now.year, now.month, now.day - 2),
      rangeEnd: DateTime(now.year, now.month, now.day + 4),
      service: BwfLiveService(fetcher: (code, date) async => _dayMatches()),
    )));
    await tester.pump();
    await tester.pump();

    // 状态筛选：只看已结束 → 未开赛的男单卡消失
    await tester.tap(find.text('已结束'));
    await tester.pump();
    expect(find.text('10:25'), findsNothing);
    expect(find.text('女单'), findsNWidgets(2)); // 筛选 chip + 卡片徽章
    // 项目筛选叠加：女单 → 已结束的女单卡仍在（chip+徽章），切回全部状态
    await tester.tap(find.text('女单').first);
    await tester.pump();
    expect(find.text('✓ 已结束'), findsOneWidget);
    // 只看未开赛 + 女单 → 无符合条件
    await tester.tap(find.text('未开赛'));
    await tester.pump();
    expect(find.text('无符合条件的对阵'), findsOneWidget);
  });

  testWidgets('拉取失败显示错误态与重试按钮', (tester) async {
    final now = DateTime.now();
    final service = BwfLiveService(
        fetcher: (code, date) async => throw Exception('network down'));
    await tester.pumpWidget(_wrap(BwfMatchesPage(
      tournamentName: 'x',
      tournamentCode: 'c',
      tournamentId: 1,
      rangeStart: DateTime(now.year, now.month, now.day - 2),
      rangeEnd: DateTime(now.year, now.month, now.day + 4),
      service: service)));
    await tester.pump();
    await tester.pump();

    expect(find.text('拉取当日赛况失败，请检查网络后重试'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });
}
