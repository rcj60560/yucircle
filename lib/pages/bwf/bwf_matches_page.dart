import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/theme.dart';
import '../../models/bwf_match.dart';
import '../../services/bwf_live_service.dart';

/// 当日赛况页：进行中赛事的当日对阵，按场地分组（官方对阵顺序）+ 逐局比分 + 实时状态
class BwfMatchesPage extends StatefulWidget {
  final String tournamentName;
  final String tournamentCode;
  final int tournamentId; // 单场详情 h2h API 用
  final BwfLiveService? service; // 测试注入

  const BwfMatchesPage({
    super.key,
    required this.tournamentName,
    required this.tournamentCode,
    required this.tournamentId,
    this.service,
  });

  @override
  State<BwfMatchesPage> createState() => _BwfMatchesPageState();
}

class _BwfMatchesPageState extends State<BwfMatchesPage> {
  List<BwfMatch>? _matches;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final matches = await (widget.service ?? BwfLiveService())
          .fetchDayMatches(widget.tournamentCode, DateTime.now());
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: SportPalette.textSecondary)),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('重试')),
                    ],
                  ),
                )
              : (_matches == null || _matches!.isEmpty)
                  ? const Center(
                      child: Text('当日暂无对阵',
                          style: TextStyle(color: SportPalette.textSecondary)))
                  : _list(_matches!),
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
