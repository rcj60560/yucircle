import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/theme.dart';
import '../../models/bwf_match.dart';
import '../../services/bwf_live_service.dart';

/// 当日赛况页：赛事日期范围内逐日切换 + 项目/状态筛选 + 按场地分组（官方对阵顺序）
class BwfMatchesPage extends StatefulWidget {
  final String tournamentName;
  final String tournamentCode;
  final int tournamentId; // 单场详情 h2h API 用
  final DateTime rangeStart; // 赛事起止（日期条范围）
  final DateTime rangeEnd;
  final BwfLiveService? service; // 测试注入

  const BwfMatchesPage({
    super.key,
    required this.tournamentName,
    required this.tournamentCode,
    required this.tournamentId,
    required this.rangeStart,
    required this.rangeEnd,
    this.service,
  });

  @override
  State<BwfMatchesPage> createState() => _BwfMatchesPageState();
}

class _BwfMatchesPageState extends State<BwfMatchesPage> {
  List<BwfMatch>? _matches;
  String? _error;
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();
  String? _eventFilter; // null = 全部；'MS'…'XD'
  BwfMatchStatus? _statusFilter; // null = 全部

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(widget.rangeStart.year, widget.rangeStart.month,
        widget.rangeStart.day);
    final end =
        DateTime(widget.rangeEnd.year, widget.rangeEnd.month, widget.rangeEnd.day);
    // 默认选中今天；不在赛事范围内则取最近的一天
    if (today.isBefore(start)) {
      _selectedDate = start;
    } else if (today.isAfter(end)) {
      _selectedDate = end;
    } else {
      _selectedDate = today;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final matches = await (widget.service ?? BwfLiveService())
          .fetchDayMatches(widget.tournamentCode, _selectedDate);
      setState(() {
        _matches = matches;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = '拉取当日赛况失败，请检查网络后重试';
        _loading = false;
      });
    }
  }

  void _selectDate(DateTime d) {
    if (d == _selectedDate) return;
    setState(() {
      _selectedDate = d;
      _eventFilter = null; // 换日后项目/状态回“全部”，避免跨日残留
      _statusFilter = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SportPalette.bg,
      appBar: AppBar(
        title: Text('${widget.tournamentName} · 当日赛况'),
        actions: [
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          _dateBar(),
          if (_matches != null && _matches!.isNotEmpty) ...[_filterBar()],
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!,
                                style: const TextStyle(color: SportPalette.textSecondary)),
                            const SizedBox(height: 12),
                            FilledButton(onPressed: _load, child: const Text('重试')),
                          ],
                        ),
                      )
                    : (_matches == null || _matches!.isEmpty)
                        ? const Center(
                            child: Text('当日暂无对阵',
                                style: TextStyle(color: SportPalette.textSecondary)))
                        : _filtered().isEmpty
                            ? const Center(
                                child: Text('无符合条件的对阵',
                                    style:
                                        TextStyle(color: SportPalette.textSecondary)))
                            : _list(_filtered()),
          ),
        ],
      ),
    );
  }

  List<BwfMatch> _filtered() {
    var list = _matches ?? const <BwfMatch>[];
    if (_eventFilter != null) {
      list = list.where((m) => m.eventName == _eventFilter).toList();
    }
    if (_statusFilter != null) {
      list = list.where((m) => m.status == _statusFilter).toList();
    }
    return list;
  }

  /// 日期条：赛事起止范围内逐日 chip，默认今天（越界取最近日）
  Widget _dateBar() {
    final start = DateTime(
        widget.rangeStart.year, widget.rangeStart.month, widget.rangeStart.day);
    final end =
        DateTime(widget.rangeEnd.year, widget.rangeEnd.month, widget.rangeEnd.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final days = <DateTime>[
      for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) d
    ];
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          for (final d in days)
            _dateChip(d, isToday: d == today, weekday: weekdays[d.weekday - 1]),
        ],
      ),
    );
  }

  Widget _dateChip(DateTime d, {required bool isToday, required String weekday}) {
    final on = d == _selectedDate;
    return GestureDetector(
      onTap: () => _selectDate(d),
      child: Container(
        width: 44,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: on ? SportPalette.green : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: on ? SportPalette.green : const Color(0xFFE1EAE4), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${d.day}',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: on ? Colors.white : SportPalette.textPrimary)),
            Text(
              isToday ? '今天' : weekday,
              style: TextStyle(
                  fontSize: 9,
                  color: on
                      ? Colors.white
                      : isToday
                          ? SportPalette.green
                          : SportPalette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// 筛选条：项目（当日出现过的）+ 状态
  Widget _filterBar() {
    final events = <String>{...?_matches?.map((m) => m.eventName)}.toList()
      ..sort(); // MS<WS<MD? 字典序 MD<MS<WD<WS<XD，无妨
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _chip('全部项目', _eventFilter == null, () => setState(() => _eventFilter = null)),
          for (final e in events)
            _chip(eventNamesZh[e] ?? e, _eventFilter == e,
                // 反选：再次点击已选中的项目 → 取消，回到全部
                () => setState(() => _eventFilter = _eventFilter == e ? null : e)),
          const SizedBox(width: 8),
          _chip('全部状态', _statusFilter == null, () => setState(() => _statusFilter = null)),
          for (final (label, value) in [
            ('进行中', BwfMatchStatus.inProgress),
            ('已结束', BwfMatchStatus.finished),
            ('未开赛', BwfMatchStatus.upcoming),
          ])
            _chip(label, _statusFilter == value,
                // 反选：再次点击已选中的状态 → 取消，回到全部
                () => setState(() => _statusFilter = _statusFilter == value ? null : value)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: on ? SportPalette.blue.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: on ? SportPalette.blue : const Color(0xFFE1EAE4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: on ? FontWeight.w800 : FontWeight.w500,
            color: on ? SportPalette.blue : SportPalette.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _list(List<BwfMatch> matches) {
    // 按场地分组：场地顺序与组内顺序都保持 API 原序（官方对阵顺序）
    final groups = <String, List<BwfMatch>>{};
    for (final m in matches) {
      (groups[m.courtName] ??= []).add(m);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: groups.length,
      itemBuilder: (context, gi) {
        final court = groups.keys.elementAt(gi);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 6),
              child: Text(court,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: SportPalette.blue)),
            ),
            for (final m in groups[court]!) _card(m),
          ],
        );
      },
    );
  }

  Widget _card(BwfMatch m) {
    final (statusText, statusColor) = switch (m.status) {
      BwfMatchStatus.finished => ('✓ 已结束', SportPalette.textSecondary),
      BwfMatchStatus.inProgress => ('● 进行中', SportPalette.danger),
      BwfMatchStatus.upcoming => (
          '${m.matchTime.hour.toString().padLeft(2, '0')}:${m.matchTime.minute.toString().padLeft(2, '0')}',
          SportPalette.blue
        ),
    };
    return GestureDetector(
      onTap: () => Get.toNamed('/bwf-match-detail',
          arguments: {'match': m, 'tmtId': widget.tournamentId}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Color(0x140084C6), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6), color: SportPalette.blue),
                  child: Text(m.eventNameZh,
                      style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                const SizedBox(width: 6),
                Text(m.roundName,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: SportPalette.textPrimary)),
                const Spacer(),
                Text(statusText, style: TextStyle(fontSize: 10, color: statusColor)),
              ],
            ),
            const SizedBox(height: 8),
            _teamRow(m, 1),
            const SizedBox(height: 4),
            _teamRow(m, 2),
          ],
        ),
      ),
    );
  }

  /// 一方一行：左国旗+球员信息，右逐局得分（胜方加粗、负方置灰）
  Widget _teamRow(BwfMatch m, int side) {
    final team = side == 1 ? m.team1 : m.team2;
    final won = m.winner == side;
    final lost = m.winner != 0 && !won;
    final nameStyle = TextStyle(
      fontSize: 12,
      fontWeight: won ? FontWeight.w800 : FontWeight.w600,
      color: lost ? SportPalette.textSecondary : SportPalette.textPrimary,
    );
    TextStyle scoreStyle(bool currentSetBold) => TextStyle(
          fontSize: 12,
          fontWeight: currentSetBold ? FontWeight.w800 : FontWeight.w500,
          color: lost ? SportPalette.textSecondary : SportPalette.textPrimary,
        );
    return Row(
      children: [
        _flag(team.flagUrl, team.countryCode),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: team.display, style: nameStyle),
              if (team.seed != null)
                TextSpan(
                  text: ' [${team.seed}]',
                  style: const TextStyle(
                      fontSize: 10, color: SportPalette.goldDark),
                ),
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        for (final (i, s) in m.sets.indexed)
          SizedBox(
            width: 30,
            child: Text('${side == 1 ? s.home : s.away}',
                textAlign: TextAlign.center,
                style: scoreStyle(won ||
                    (m.status == BwfMatchStatus.inProgress && i == m.sets.length - 1))),
          ),
      ],
    );
  }

  /// 圆形国旗；加载失败/缺失回退国家码文字
  Widget _flag(String? url, String code) {
    if (url == null || url.isEmpty) {
      return SizedBox(
        width: 16,
        height: 16,
        child: Center(
            child: Text(code,
                style:
                    const TextStyle(fontSize: 7, color: SportPalette.textSecondary))),
      );
    }
    return Image.network(
      url,
      width: 16,
      height: 16,
      errorBuilder: (_, _, _) => SizedBox(
        width: 16,
        height: 16,
        child: Center(
            child: Text(code,
                style:
                    const TextStyle(fontSize: 7, color: SportPalette.textSecondary))),
      ),
    );
  }
}
