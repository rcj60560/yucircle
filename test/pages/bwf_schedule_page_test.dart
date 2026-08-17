import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yucircle/models/bwf_schedule.dart';
import 'package:yucircle/pages/bwf/bwf_schedule_page.dart';

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// 相对日期夹具：已完成站（now-60d ~ now-55d，S1000）+ 未开赛站（now+5d ~ now+7d，
/// S750），按 startDate 升序排列 —— 页面的月分组插入序与 next.first 逻辑依赖升序输入。
ScheduleData _data(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final completedStart = DateTime(today.year, today.month, today.day - 60);
  final completedEnd = DateTime(today.year, today.month, today.day - 55);
  final upcomingStart = DateTime(today.year, today.month, today.day + 5);
  final upcomingEnd = DateTime(today.year, today.month, today.day + 7);
  return ScheduleData.fromJson({
    'year': upcomingStart.year,
    'tournaments': [
      {
        'name': 'PETRONAS Malaysia Open',
        'startDate': _ymd(completedStart),
        'endDate': _ymd(completedEnd),
        'city': 'Kuala Lumpur',
        'level': 'super1000',
        'prizeMoney': 1450000,
      },
      {
        'name': 'LI-NING China Masters',
        'startDate': _ymd(upcomingStart),
        'endDate': _ymd(upcomingEnd),
        'city': 'Shenzhen',
        'level': 'super750',
        'prizeMoney': 1150000,
      },
    ],
  });
}

void main() {
  testWidgets('时间轴渲染赛事、月份、下一站标记与升序排列', (tester) async {
    final data = _data(DateTime.now());
    final upcoming = data.tournaments.firstWhere(
        (t) => t.statusOn(DateTime.now()) == TournamentStatus.upcoming);
    await tester.pumpWidget(MaterialApp(home: BwfSchedulePage(data: data)));
    expect(find.text('LI-NING China Masters'), findsOneWidget);
    expect(find.text('PETRONAS Malaysia Open'), findsOneWidget);
    expect(find.text('${upcoming.startDate.month}月'), findsWidgets);
    expect(find.text('▶ 下一站'), findsOneWidget);
    expect(find.text('S750'), findsOneWidget);
    expect(find.text('S1000'), findsOneWidget);
    // 排序契约：已完成站（开赛更早）的卡片必须渲染在未开赛站卡片上方
    final completedTop = tester.getTopLeft(find.text('PETRONAS Malaysia Open')).dy;
    final upcomingTop = tester.getTopLeft(find.text('LI-NING China Masters')).dy;
    expect(completedTop, lessThan(upcomingTop));
  });
}
