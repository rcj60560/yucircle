import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yucircle/services/bwf_data_service.dart';

const _remoteJson = '{"updatedAt":"2026-08-14T09:00:00+08:00","disciplines":{"ms":{"name":"男单","entries":[{"rank":1,"change":0,"country":"TPE","player":"REMOTE","points":1}]}}}';
const _assetJson = '{"updatedAt":"2026-08-01T09:00:00+08:00","disciplines":{"ms":{"name":"男单","entries":[{"rank":1,"change":0,"country":"TPE","player":"ASSET","points":1}]}}}';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('远端成功 → 用远端并写缓存', () async {
    final svc = BwfDataService(
      remoteFetcher: (url) async => _remoteJson,
      assetLoader: (path) async => _assetJson,
    );
    final data = await svc.loadRankings();
    expect(data.disciplines['ms']!.entries.first.player, 'REMOTE');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('bwf_rankings_cache'), _remoteJson);
  });

  test('远端失败且无缓存 → 用内置 asset', () async {
    final svc = BwfDataService(
      remoteFetcher: (url) async => null,
      assetLoader: (path) async => _assetJson,
    );
    final data = await svc.loadRankings();
    expect(data.disciplines['ms']!.entries.first.player, 'ASSET');
  });

  test('远端失败但有缓存 → 用缓存', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bwf_rankings_cache', _remoteJson);
    final svc = BwfDataService(
      remoteFetcher: (url) async => null,
      assetLoader: (path) async => _assetJson,
    );
    final data = await svc.loadRankings();
    expect(data.disciplines['ms']!.entries.first.player, 'REMOTE');
  });
}
