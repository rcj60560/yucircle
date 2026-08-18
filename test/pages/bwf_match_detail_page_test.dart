import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yucircle/models/bwf_match.dart';
import 'package:yucircle/pages/bwf/bwf_match_detail_page.dart';
import 'package:yucircle/services/bwf_live_service.dart';

BwfMatch _match() => BwfMatch.fromJson({
      'code': '553', 'duration': 33,
      'eventName': 'XD', 'roundName': 'R64', 'courtName': 'Court 2',
      'matchTime': '2026-08-18 10:45:00', 'matchStatusValue': 'Finished', 'winner': 2,
      'team1seed': null, 'team2seed': '3',
      'score': [
        {'set': 1, 'home': 16, 'away': 21},
        {'set': 2, 'home': 19, 'away': 21},
      ],
      'team1': {
        'countryCode': 'MAS',
        'countryFlagUrl': 'https://img.bwfbadminton.com/flags/MAS.png',
        'players': [
          {'nameShort': 'WONG T C ', 'nameDisplay': 'WONG Tien Ci'},
          {'nameShort': 'LIM C S ', 'nameDisplay': 'LIM Chiew Sien'},
        ],
      },
      'team2': {
        'countryCode': 'INA',
        'countryFlagUrl': 'https://img.bwfbadminton.com/flags/INA.png',
        'players': [
          {'nameShort': 'KUSHARJANTO', 'nameDisplay': 'Rehan Naufal KUSHARJANTO'},
          {'nameShort': 'G WIDJAJA', 'nameDisplay': 'Gloria Emanuelle WIDJAJA'},
        ],
      },
    });

BwfLiveService _statsService() => BwfLiveService(statsFetcher: (tmtId, code) async => {
      'info': {'drawName': 'XD', 'roundName': 'R64', 'winner': 2},
      'location': {'locationName': 'Indra Gandhi Indoor Stadium'},
      'progress': {'duration': 33},
      'games': [
        {
          'team1': 16,
          'team2': 21,
          'match_set_details_model': [
            for (var i = 0; i < 4; i++) {'ordering': i + 1, 'team1': i % 2, 'team2': 1 - i % 2},
          ],
          'match_set_stats_model': {
            'team1_rallies_won': 16,
            'team2_rallies_won': 21,
            'team1_consecutive_points': 4,
            'team2_consecutive_points': 6,
          },
        },
        {
          'team1': 19,
          'team2': 21,
          'match_set_details_model': [
            {'ordering': 1, 'team1': 1, 'team2': 0},
          ],
          'match_set_stats_model': {'team1_rallies_won': 19, 'team2_rallies_won': 21},
        },
      ],
    });

void main() {
  testWidgets('单场详情：双方全名/种子/逐局比分/得分曲线图', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BwfMatchDetailPage(match: _match(), tournamentId: 5601, service: _statsService()),
    ));
    await tester.pump(); // stats 到达
    await tester.pump();

    // 标题与状态
    expect(find.text('混双 R64'), findsOneWidget);
    expect(find.text('✓ 已结束'), findsOneWidget);
    expect(find.textContaining('Court 2'), findsOneWidget);
    expect(find.textContaining('33 分钟'), findsOneWidget);
    // 双方全名与种子
    expect(find.text('WONG Tien Ci'), findsOneWidget);
    expect(find.text('Gloria Emanuelle WIDJAJA'), findsOneWidget);
    expect(find.textContaining('种子3'), findsOneWidget);
    // 逐局比分大字
    expect(find.text('16-21'), findsOneWidget);
    expect(find.text('19-21'), findsOneWidget);
    // 得分曲线区：tab + CustomPaint
    expect(find.text('得分曲线'), findsOneWidget);
    expect(find.text('局1 16-21'), findsOneWidget);
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
  });

  testWidgets('逐分数据拉取失败时降级提示（不阻塞基础信息）', (tester) async {
    final service = BwfLiveService(
        statsFetcher: (tmtId, code) async => throw Exception('down'));
    await tester.pumpWidget(MaterialApp(
      home: BwfMatchDetailPage(match: _match(), tournamentId: 5601, service: service),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('逐分数据暂不可用'), findsOneWidget);
    expect(find.text('16-21'), findsOneWidget); // 基础信息仍在
  });
}
