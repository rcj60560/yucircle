import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/bwf_ranking.dart';
import '../../models/bwf_schedule.dart';
import '../../services/bwf_data_service.dart';
import 'bwf_rankings_page.dart';
import 'bwf_schedule_page.dart';

/// 羽联 Tab：渐变头 + 排名|赛程 分段（spec §6.2/6.3）
class BwfHomePage extends StatefulWidget {
  const BwfHomePage({super.key});

  @override
  State<BwfHomePage> createState() => _BwfHomePageState();
}

class _BwfHomePageState extends State<BwfHomePage> {
  final _service = BwfDataService();
  int _section = 0; // 0 排名 1 赛程
  RankingsData? _rankings;
  ScheduleData? _schedule;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await _service.loadRankings();
      final s = await _service.loadSchedule();
      if (mounted) {
        setState(() {
          _rankings = r;
          _schedule = s;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '数据加载失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SportPalette.bg,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: const BoxDecoration(gradient: SportPalette.headerGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '羽联 🏸',
                      style: TextStyle(
                          color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Text(
                      '数据更新于 ${_updatedLabel()}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(children: [_segment('排名', 0), _segment('赛程', 1)]),
                ),
              ],
            ),
          ),
          Expanded(
            child: _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!,
                          style: const TextStyle(color: SportPalette.textSecondary)),
                    ),
                  )
                : _rankings == null || _schedule == null
                    ? const Center(
                        child: CircularProgressIndicator(color: SportPalette.green))
                    : RefreshIndicator(
                        color: SportPalette.green,
                        onRefresh: _load,
                        child: _section == 0
                            ? BwfRankingsPage(data: _rankings!)
                            : BwfSchedulePage(data: _schedule!),
                      ),
          ),
        ],
      ),
    );
  }

  String _updatedLabel() {
    final d = _section == 0 ? _rankings?.updatedAt : _schedule?.updatedAt;
    if (d == null || d.year <= 2000) return '—';
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$m-$day';
  }

  Widget _segment(String label, int index) {
    final on = _section == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _section = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: on ? SportPalette.blue : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
