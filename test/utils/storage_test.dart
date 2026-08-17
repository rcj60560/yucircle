import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yucircle/utils/storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saveMockLogin 写入后登录态与资料齐备（供 Splash 调试绕过）', () async {
    await StorageManager.saveMockLogin();
    expect(await StorageManager.isLoggedIn(), isTrue);
    expect(await StorageManager.isProfileSet(), isTrue);
    final info = await StorageManager.getUserInfo();
    expect(info['userId'], isNotNull);
    expect(info['nickname'], isNotEmpty);
    expect(info['phone'], isNotNull);
  });
}
