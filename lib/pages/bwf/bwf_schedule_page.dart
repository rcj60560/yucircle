import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/bwf_schedule.dart';

/// 赛程页：月度时间轴 + 级别徽章 + 下一站高亮（spec §6.3）
class BwfSchedulePage extends StatelessWidget {
  final ScheduleData data;

  const BwfSchedulePage({super.key, required this.data});

  (Color, String) _levelStyle(TournamentLevel l) {
    switch (l) {
      case TournamentLevel.major:
        return (SportPalette.danger, '大赛');
      case TournamentLevel.super1000:
        return (SportPalette.goldDark, 'S1000');
      case TournamentLevel.super750:
        return (SportPalette.levelS750, 'S750');
      case TournamentLevel.super500:
        return (SportPalette.levelS500, 'S500');
      case TournamentLevel.super300:
        return (SportPalette.green, 'S300');
      case TournamentLevel.finals:
        return (SportPalette.textPrimary, 'FINALS');
      case TournamentLevel.other:
        return (SportPalette.textSecondary, '其他');
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final next = data.tournaments
        .where((t) => t.statusOn(now) == TournamentStatus.upcoming)
        .toList();

    // 按开赛月分组（保持升序）
    final groups = <String, List<Tournament>>{};
    for (final t in data.tournaments) {
      final key = '${t.startDate.year}-${t.startDate.month.toString().padLeft(2, '0')}';
      (groups[key] ??= []).add(t);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: groups.length,
      itemBuilder: (context, gi) {
        final key = groups.keys.elementAt(gi);
        final month = int.parse(key.split('-')[1]);
        final isNextMonth =
            next.isNotEmpty && next.first.startDate.month == month;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧月份轴
            SizedBox(
              width: 44,
              child: Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isNextMonth ? SportPalette.green : Colors.white,
                      border: Border.all(
                          color: isNextMonth ? SportPalette.green : const Color(0xFFE1EAE4),
                          width: 2),
                    ),
                    child: Text('$month月',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isNextMonth
                                ? Colors.white
                                : SportPalette.textPrimary)),
                  ),
                  if (gi != groups.length - 1)
                    Container(width: 2, height: _groupHeight(groups[key]!), color: const Color(0xFFD5E3DB)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 右侧赛事卡
            Expanded(
              child: Column(
                children: [
                  for (final t in groups[key]!) _card(t, isNext: identical(t, next.isNotEmpty ? next.first : null)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // 粗略估高让连线不断档：每张卡 ~78
  double _groupHeight(List<Tournament> list) => list.length * 84.0 + 8;

  Widget _card(Tournament t, {required bool isNext}) {
    final (color, label) = _levelStyle(t.level);
    final status = t.statusOn(DateTime.now());
    final (statusText, statusColor) = switch (status) {
      TournamentStatus.completed => ('✓ 已结束', SportPalette.textSecondary),
      TournamentStatus.ongoing => ('● 进行中', SportPalette.danger),
      TournamentStatus.upcoming => ('未开赛', SportPalette.blue),
    };
    final range =
        '${t.startDate.month}/${t.startDate.day} - ${t.endDate.month}/${t.endDate.day}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x140084C6), blurRadius: 8, offset: Offset(0, 2)),
        ],
        border: isNext ? Border.all(color: SportPalette.green, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: color),
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const Spacer(),
              if (isNext)
                const Text('▶ 下一站',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w800, color: SportPalette.green))
              else
                Text(statusText,
                    style: TextStyle(fontSize: 10, color: statusColor)),
            ],
          ),
          const SizedBox(height: 6),
          Text(t.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: SportPalette.textPrimary)),
          const SizedBox(height: 4),
          Text(
            '$range · ${t.city}${t.prizeMoney > 0 ? ' · \$${_fmt(t.prizeMoney)}' : ''}',
            style: const TextStyle(fontSize: 11, color: SportPalette.textSecondary),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    var s = n.toString();
    final buf = StringBuffer();
    while (s.length > 3) {
      buf.write(',${s.substring(s.length - 3)}');
      s = s.substring(0, s.length - 3);
    }
    return '$s$buf';
  }
}
