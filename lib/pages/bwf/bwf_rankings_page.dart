import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/bwf_ranking.dart';

const _disciplineOrder = ['ms', 'ws', 'md', 'wd', 'xd'];

/// 排名页：单项 chips + 徽章列表（spec §6.2）
class BwfRankingsPage extends StatefulWidget {
  final RankingsData data;

  const BwfRankingsPage({super.key, required this.data});

  @override
  State<BwfRankingsPage> createState() => _BwfRankingsPageState();
}

class _BwfRankingsPageState extends State<BwfRankingsPage> {
  String _current = 'ms';

  @override
  Widget build(BuildContext context) {
    final keys =
        _disciplineOrder.where((k) => widget.data.disciplines.containsKey(k)).toList();
    final discipline = widget.data.disciplines[_current] ??
        widget.data.disciplines[keys.first]!;

    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              for (final k in keys)
                _chip(k, discipline: widget.data.disciplines[k]!.name),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            itemCount: discipline.entries.length,
            itemBuilder: (context, i) => _row(discipline.entries[i]),
          ),
        ),
      ],
    );
  }

  Widget _chip(String key, {required String discipline}) {
    final on = _current == key;
    return GestureDetector(
      onTap: () => setState(() => _current = key),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: on ? Colors.white : SportPalette.green.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? SportPalette.green : Colors.transparent),
        ),
        child: Text(
          discipline,
          style: TextStyle(
            fontSize: 13,
            fontWeight: on ? FontWeight.w800 : FontWeight.w500,
            color: on ? SportPalette.blue : SportPalette.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _row(RankingEntry e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x140084C6), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          _rankBadge(e.rank),
          const SizedBox(width: 8),
          Text(
            e.country,
            style: const TextStyle(fontSize: 10, color: SportPalette.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              e.player,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: SportPalette.textPrimary),
            ),
          ),
          _changeLabel(e.change),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            child: Text(
              e.points.toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: SportPalette.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankBadge(int rank) {
    Color? bg;
    if (rank == 1) bg = SportPalette.goldDark;
    if (rank == 2) bg = SportPalette.silver;
    if (rank == 3) bg = SportPalette.bronze;
    if (bg != null) {
      return Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: bg),
        child: Text('$rank',
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
      );
    }
    return SizedBox(
      width: 24,
      child: Text('$rank',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: SportPalette.textPrimary)),
    );
  }

  Widget _changeLabel(int change) {
    if (change > 0) {
      return Text('▲$change',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SportPalette.green));
    }
    if (change < 0) {
      return Text('▼${-change}',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SportPalette.danger));
    }
    return const Text('—',
        style: TextStyle(fontSize: 10, color: SportPalette.textSecondary));
  }
}
