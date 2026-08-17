import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bwf_ranking.dart';
import '../models/bwf_schedule.dart';

/// BWF 数据取数：远端 raw JSON → 本地缓存 → 打包内置 asset（spec §5.2）
class BwfDataService {
  static const _base =
      'https://raw.githubusercontent.com/rcj60560/yucircle/main/assets/data/bwf';
  static const _rankingsUrl = '$_base/rankings.json';
  static const _scheduleUrl = '$_base/schedule.json';
  static const _rankingsCacheKey = 'bwf_rankings_cache';
  static const _scheduleCacheKey = 'bwf_schedule_cache';

  /// 测试注入口
  final Future<String?> Function(String url)? remoteFetcher;
  final Future<String> Function(String assetPath)? assetLoader;

  BwfDataService({this.remoteFetcher, this.assetLoader});

  Future<RankingsData> loadRankings() async => RankingsData.fromJson(
      await _load(_rankingsUrl, _rankingsCacheKey, 'assets/data/bwf/rankings.json'));

  Future<ScheduleData> loadSchedule() async => ScheduleData.fromJson(
      await _load(_scheduleUrl, _scheduleCacheKey, 'assets/data/bwf/schedule.json'));

  Future<Map<String, dynamic>> _load(
      String url, String cacheKey, String assetPath) async {
    // 1) 远端（解码成功才写缓存）
    try {
      final remote = await (remoteFetcher != null
          ? remoteFetcher!(url)
          : _dioGet(url));
      if (remote != null && remote.isNotEmpty) {
        final decoded =
            Map<String, dynamic>.from(jsonDecode(remote) as Map);
        (await SharedPreferences.getInstance()).setString(cacheKey, remote);
        return decoded;
      }
    } catch (_) {/* 落到下一层 */}
    // 2) 本地缓存（解码失败降级到内置资产）
    try {
      final cached = (await SharedPreferences.getInstance()).getString(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return Map<String, dynamic>.from(jsonDecode(cached) as Map);
      }
    } catch (_) {/* 落到下一层 */}
    // 3) 内置资产
    final bundled =
        await (assetLoader != null ? assetLoader!(assetPath) : rootBundle.loadString(assetPath));
    return Map<String, dynamic>.from(jsonDecode(bundled) as Map);
  }

  Future<String?> _dioGet(String url) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final r = await dio.get<String>(url);
      return r.statusCode == 200 ? r.data : null;
    } catch (_) {
      return null;
    }
  }
}
