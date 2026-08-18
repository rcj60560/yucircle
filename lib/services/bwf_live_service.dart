import 'package:dio/dio.dart';

import '../models/bwf_match.dart';

/// 当日赛况直连 extranet-lv day-matches（实时数据：不缓存、不落库）
class BwfLiveService {
  static const _api =
      'https://extranet-lv.bwfbadminton.com/api/tournaments/day-matches';

  /// 测试注入口：返回原始 JSON 数组
  final Future<List<dynamic>> Function(String code, String date)? fetcher;

  BwfLiveService({this.fetcher});

  Future<List<BwfMatch>> fetchDayMatches(String tournamentCode, DateTime date) async {
    final dateStr = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    List<dynamic> raw;
    if (fetcher != null) {
      raw = await fetcher!(tournamentCode, dateStr);
    } else {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Accept': 'application/json'},
      ));
      final r = await dio.get<List<dynamic>>(_api, queryParameters: {
        'tournamentCode': tournamentCode,
        'date': dateStr,
        'order': 1,
        'court': 0,
      });
      raw = r.data ?? [];
    }
    final matches = raw
        .map((m) => BwfMatch.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList();
    // 按场地分组序：场地名 → 开赛时间
    matches.sort((a, b) {
      final c = a.courtName.compareTo(b.courtName);
      return c != 0 ? c : a.matchTime.compareTo(b.matchTime);
    });
    return matches;
  }
}
