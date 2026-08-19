import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/bwf_match.dart';
import '../../models/bwf_match_stats.dart';
import '../../services/bwf_live_service.dart';

/// 单场详情：对阵双方（头像/全名/国旗/种子）+ 逐局比分 + 逐局得分曲线图
class BwfMatchDetailPage extends StatefulWidget {
  final BwfMatch match;
  final int tournamentId;
  final BwfLiveService? service; // 测试注入

  const BwfMatchDetailPage({
    super.key,
    required this.match,
    required this.tournamentId,
    this.service,
  });

  @override
  State<BwfMatchDetailPage> createState() => _BwfMatchDetailPageState();
}

class _BwfMatchDetailPageState extends State<BwfMatchDetailPage> {
  BwfMatchStats? _stats;
  bool _statsFailed = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await (widget.service ?? BwfLiveService())
          .fetchMatchStats(widget.tournamentId, widget.match.matchCode);
      if (!mounted) return;
      setState(() => _stats = stats);
    } catch (_) {
      if (mounted) setState(() => _statsFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    return Scaffold(
      backgroundColor: SportPalette.bg,
      appBar: AppBar(title: Text('${m.eventNameZh} ${m.roundName}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        children: [
          _infoCard(m),
          const SizedBox(height: 8),
          _playersCard(m),
          const SizedBox(height: 8),
          _scoreCard(m),
          const SizedBox(height: 8),
          if (_stats != null && _stats!.games.isNotEmpty) ...[
            _curveSection(m, _stats!),
          ] else if (_statsFailed)
            const _SectionCard(child: Text('逐分数据暂不可用',
                style: TextStyle(fontSize: 12, color: SportPalette.textSecondary)))
          else
            const _SectionCard(
                child: Center(
                    child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)))),
                ),
        ],
      ),
    );
  }

  Widget _infoCard(BwfMatch m) {
    final (statusText, statusColor) = switch (m.status) {
      BwfMatchStatus.finished => ('✓ 已结束', SportPalette.textSecondary),
      BwfMatchStatus.inProgress => ('● 进行中', SportPalette.danger),
      BwfMatchStatus.upcoming => ('未开赛', SportPalette.blue),
    };
    final duration = m.durationMin ?? _stats?.durationMin;
    final time =
        '${m.matchTime.month}/${m.matchTime.day} ${m.matchTime.hour.toString().padLeft(2, '0')}:${m.matchTime.minute.toString().padLeft(2, '0')}';
    return _SectionCard(
      child: Row(
        children: [
          Text(statusText,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: statusColor)),
          const Spacer(),
          Text('$time · ${m.courtName}${duration != null ? ' · $duration 分钟' : ''}',
              style: const TextStyle(
                  fontSize: 12, color: SportPalette.textSecondary)),
        ],
      ),
    );
  }

  Widget _playersCard(BwfMatch m) {
    return _SectionCard(
      child: Row(
        children: [
          Expanded(child: _playerColumn(m.team1, m.winner == 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('VS',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: SportPalette.textSecondary.withValues(alpha: 0.6))),
          ),
          Expanded(child: _playerColumn(m.team2, m.winner == 2)),
        ],
      ),
    );
  }

  Widget _playerColumn(BwfMatchTeam team, bool won) {
    return Column(
      children: [
        for (final p in team.players)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _avatar(p.avatarUrl, p.nameDisplay),
                const SizedBox(width: 6),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nameDisplay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: won ? FontWeight.w800 : FontWeight.w600,
                          color: SportPalette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _flag(team.flagUrl, team.countryCode, size: 18),
            const SizedBox(width: 4),
            Text(team.countryCode,
                style: const TextStyle(
                    fontSize: 11, color: SportPalette.textSecondary)),
            if (team.seed != null)
              Text(' 种子${team.seed}',
                  style: const TextStyle(
                      fontSize: 11, color: SportPalette.goldDark)),
          ],
        ),
      ],
    );
  }

  Widget _avatar(String? url, String name) {
    final initial = name.trim().isNotEmpty ? name.trim().substring(0, 1) : '?';
    return CircleAvatar(
      radius: 18,
      backgroundColor: SportPalette.green.withValues(alpha: 0.15),
      child: url != null
          ? ClipOval(
              child: Image.network(
                url,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Text(initial,
                    style: const TextStyle(
                        fontSize: 14, color: SportPalette.green)),
              ),
            )
          : Text(initial,
              style: const TextStyle(fontSize: 14, color: SportPalette.green)),
    );
  }

  Widget _flag(String? url, String code, {double size = 16}) {
    if (url == null || url.isEmpty) {
      return SizedBox(
          width: size,
          height: size,
          child: Text(code,
              style: const TextStyle(
                  fontSize: 8, color: SportPalette.textSecondary)));
    }
    return Image.network(
      url,
      width: size,
      height: size,
      errorBuilder: (_, _, _) => SizedBox(
          width: size,
          height: size,
          child: Text(code,
              style: const TextStyle(
                  fontSize: 8, color: SportPalette.textSecondary))),
    );
  }

  Widget _scoreCard(BwfMatch m) {
    if (m.sets.isEmpty) {
      return const _SectionCard(
          child: Text('尚未开赛',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 12, color: SportPalette.textSecondary)));
    }
    return _SectionCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final (i, s) in m.sets.indexed) ...[
            if (i > 0) const SizedBox(width: 12),
            Text('${s.home}-${s.away}',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: s.home > s.away
                        ? SportPalette.blue
                        : s.away > s.home
                            ? SportPalette.green
                            : SportPalette.textSecondary)),
          ],
        ],
      ),
    );
  }

  /// 逐局 tab：得分曲线图 + 局内统计
  Widget _curveSection(BwfMatch m, BwfMatchStats stats) {
    final games = stats.games;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('得分曲线',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: SportPalette.textPrimary)),
          // DefaultTabController：长度与内容同源（stats.games），避免与
          // match.sets 数量不一致时的 controller 长度错配崩溃
          DefaultTabController(
            length: games.length,
            child: Column(
              children: [
                if (games.length > 1)
                  TabBar(
                    labelColor: SportPalette.blue,
                    unselectedLabelColor: SportPalette.textSecondary,
                    indicatorSize: TabBarIndicatorSize.label,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      for (final (i, g) in games.indexed)
                        Tab(text: '局${i + 1} ${g.team1Score}-${g.team2Score}'),
                    ],
                  ),
                SizedBox(
                  height: 170,
                  child: TabBarView(
                    children: [
                      for (final g in games) _gameTab(m, g),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gameTab(BwfMatch m, BwfGameStats g) {
    return Column(
      children: [
        Expanded(
            child: ScoreCurveChart(
          points: g.points,
          name1: m.team1.display,
          name2: m.team2.display,
        )),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _statChip('${m.team1.countryCode} 得分 ${g.team1Score}', SportPalette.blue),
            const SizedBox(width: 8),
            if (g.team1Consecutive != null)
              _statChip('连续最多 ${g.team1Consecutive}', SportPalette.blue),
            const SizedBox(width: 12),
            _statChip('${m.team2.countryCode} 得分 ${g.team2Score}', SportPalette.green),
            const SizedBox(width: 8),
            if (g.team2Consecutive != null)
              _statChip('连续最多 ${g.team2Consecutive}', SportPalette.green),
          ],
        ),
      ],
    );
  }

  Widget _statChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x140084C6), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

/// 逐分得分曲线（对齐官网）：横轴=第几分序号，两条折线直接绘制
/// 数据自带的【累计得分】（勿再累加），每分一个圆点 + 虚线网格 + 底部图例
class ScoreCurveChart extends StatelessWidget {
  final List<GamePoint> points;
  final String name1;
  final String name2;

  const ScoreCurveChart({
    super.key,
    required this.points,
    required this.name1,
    required this.name2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: CustomPaint(size: Size.infinite, painter: _CurvePainter(points: points))),
        SizedBox(
          height: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(SportPalette.blue),
              const SizedBox(width: 4),
              Flexible(
                  child: Text(name1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, color: SportPalette.textPrimary))),
              const SizedBox(width: 12),
              _legendDot(SportPalette.green),
              const SizedBox(width: 4),
              Flexible(
                  child: Text(name2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, color: SportPalette.textPrimary))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color c) =>
      Container(width: 7, height: 7, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

class _CurvePainter extends CustomPainter {
  final List<GamePoint> points;

  _CurvePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final w = size.width, h = size.height;
    final n = points.length;
    final maxScore = math.max(
        21,
        points.fold(
            0, (m, p) => math.max(m, math.max(p.team1, p.team2))));
    const left = 20.0, right = 8.0, top = 6.0, bottom = 6.0;
    double x(int i) =>
        left + (n == 1 ? 0 : i / (n - 1) * (w - left - right));
    double y(int s) => top + (1 - s / maxScore) * (h - top - bottom);

    final grid = Paint()
      ..color = SportPalette.textSecondary.withValues(alpha: 0.30)
      ..strokeWidth = 0.8;

    // 横向虚线网格：每 2 分一条 + 左侧偶数分标签
    for (var s = 0; s <= maxScore; s += 2) {
      _dashed(canvas, Offset(left, y(s)), Offset(w - right, y(s)), grid);
      _label(canvas, '$s', Offset(2, y(s) - 6),
          SportPalette.textSecondary.withValues(alpha: 0.8));
    }
    // 纵向虚线网格：每 5 分一条（无标签，同官网）
    for (var i = 4; i < n; i += 5) {
      _dashed(canvas, Offset(x(i), top), Offset(x(i), h - bottom), grid);
    }

    _drawSeries(canvas, points.map((p) => p.team1).toList(), x, y, SportPalette.blue);
    _drawSeries(canvas, points.map((p) => p.team2).toList(), x, y, SportPalette.green);
  }

  void _drawSeries(Canvas canvas, List<int> scores, double Function(int) x,
      double Function(int) y, Color color) {
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    final path = Path()..moveTo(x(0), y(scores[0]));
    canvas.drawCircle(Offset(x(0), y(scores[0])), 2.5, fill);
    for (var i = 1; i < scores.length; i++) {
      path.lineTo(x(i), y(scores[i]));
      canvas.drawCircle(Offset(x(i), y(scores[i])), 2.5, fill);
    }
    canvas.drawPath(path, line);
  }

  void _dashed(Canvas canvas, Offset from, Offset to, Paint paint) {
    const step = 6.0, on = 3.0;
    final dx = to.dx - from.dx, dy = to.dy - from.dy;
    final len = (dx * dx + dy * dy) == 0 ? 0.0 : math.sqrt(dx * dx + dy * dy);
    if (len == 0) return;
    final ux = dx / len, uy = dy / len;
    var t = 0.0;
    while (t < len) {
      final end = math.min(t + on, len);
      canvas.drawLine(Offset(from.dx + ux * t, from.dy + uy * t),
          Offset(from.dx + ux * end, from.dy + uy * end), paint);
      t += step;
    }
  }

  void _label(Canvas canvas, String text, Offset at, Color color) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(fontSize: 9, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.points.length != points.length ||
          (old.points.isNotEmpty &&
              points.isNotEmpty &&
              (old.points.last.team1 != points.last.team1 ||
                  old.points.last.team2 != points.last.team2));
}
