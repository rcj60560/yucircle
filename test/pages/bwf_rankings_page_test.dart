import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yucircle/models/bwf_ranking.dart';
import 'package:yucircle/pages/bwf/bwf_rankings_page.dart';

RankingsData _data() => RankingsData.fromJson({
      'updatedAt': '2026-08-14T09:00:00+08:00',
      'disciplines': {
        'ms': {
          'name': '男单',
          'entries': List.generate(
            5,
            (i) => {
              'rank': i + 1,
              'change': i == 0 ? 2 : 0,
              'country': 'TPE',
              'player': '选手${i + 1}号',
              'points': 60000 - i * 100,
            },
          ),
        },
      },
    });

void main() {
  testWidgets('排名页渲染选手与单项chip', (tester) async {
    await tester.pumpWidget(MaterialApp(home: BwfRankingsPage(data: _data())));
    expect(find.text('选手1号'), findsOneWidget);
    expect(find.text('选手5号'), findsOneWidget);
    expect(find.text('男单'), findsOneWidget);
  });
}
