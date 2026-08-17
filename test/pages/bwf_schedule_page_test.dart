import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yucircle/models/bwf_schedule.dart';
import 'package:yucircle/pages/bwf/bwf_schedule_page.dart';

ScheduleData _data() => ScheduleData.fromJson({
      'year': 2026,
      'tournaments': [
        {
          'name': 'LI-NING China Masters 2026',
          'startDate': '2026-09-01',
          'endDate': '2026-09-06',
          'city': 'Shenzhen',
          'level': 'super750',
          'prizeMoney': 1150000,
        },
        {
          'name': 'PETRONAS Malaysia Open 2026',
          'startDate': '2026-01-06',
          'endDate': '2026-01-11',
          'city': 'Kuala Lumpur',
          'level': 'super1000',
          'prizeMoney': 1450000,
        },
      ],
    });

void main() {
  testWidgets('时间轴渲染赛事、月份与下一站标记', (tester) async {
    await tester.pumpWidget(MaterialApp(home: BwfSchedulePage(data: _data())));
    expect(find.text('LI-NING China Masters 2026'), findsOneWidget);
    expect(find.text('PETRONAS Malaysia Open 2026'), findsOneWidget);
    expect(find.text('9月'), findsWidgets);
    expect(find.text('▶ 下一站'), findsOneWidget);
    expect(find.text('S750'), findsOneWidget);
    expect(find.text('S1000'), findsOneWidget);
  });
}
