import 'package:dio/dio.dart';

import '../models/bwf_match.dart';
import '../models/bwf_match_stats.dart';

/// 当日赛况直连 extranet-lv（实时数据：不缓存、不落库）
class BwfLiveService {
  static const _api = 'https://extranet-lv.bwfbadminton.com/api';
  static const _dayMatchesUrl = '$_api/tournaments/day-matches';
  static const _h2hMatchUrl = '$_api/h2h/match';

  /// 测试注入口：day-matches 原始数组 / h2h 单场原始 JSON
  final Future<List<dynamic>> Function(String code, String date)? fetcher;
  final Future<Map<String, dynamic>> Function(int tmtId, String matchCode)?
      statsFetcher;

  BwfLiveService({this.fetcher, this.statsFetcher});

  Dio _dio() => Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Accept': 'application/json'},
      ));

  Future<List<BwfMatch>> fetchDayMatches(String tournamentCode, DateTime date) async {
    final dateStr = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    List<dynamic> raw;
    if (fetcher != null) {
      raw = await fetcher!(tournamentCode, dateStr);
    } else {
      final r = await _dio().get<List<dynamic>>(_dayMatchesUrl, queryParameters: {
        'tournamentCode': tournamentCode,
        'date': dateStr,
        'order': 1,
        'court': 0,
      });
      raw = r.data ?? [];
    }
    // 保持 API 原序（官方对阵顺序）——"not before" 赛制下开赛时间会漂移，
    // 按时间重排会与官网对不上（2026-08-18 Court 2 实测踩坑）。
    return raw
        .map((m) => BwfMatch.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  /// 单场逐分统计（得分曲线图数据源）
  Future<BwfMatchStats> fetchMatchStats(int tmtId, String matchCode) async {
    Map<String, dynamic> json;
    if (statsFetcher != null) {
      json = await statsFetcher!(tmtId, matchCode);
    } else {
      final r = await _dio().get(_h2hMatchUrl,
          queryParameters: {'tmt_id': tmtId, 'match_code': matchCode});
      json = Map<String, dynamic>.from(r.data as Map);
    }
    return BwfMatchStats.fromJson(json);
  }
}
