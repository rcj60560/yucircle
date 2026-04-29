import 'package:shared_preferences/shared_preferences.dart';

class StorageManager {
  static const _keyToken = 'auth_token';
  static const _keyUserId = 'user_id';
  static const _keyNickname = 'nickname';
  static const _keyPhone = 'phone';
  static const _keyLevel = 'badminton_level';
  static const _keyIsProfileSet = 'is_profile_set';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> saveUserInfo({
    required String userId,
    required String phone,
    required String nickname,
    required String level,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyPhone, phone);
    await prefs.setString(_keyNickname, nickname);
    await prefs.setString(_keyLevel, level);
    await prefs.setBool(_keyIsProfileSet, true);
  }

  static Future<Map<String, String?>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(_keyUserId),
      'phone': prefs.getString(_keyPhone),
      'nickname': prefs.getString(_keyNickname),
      'level': prefs.getString(_keyLevel),
    };
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<bool> isProfileSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsProfileSet) ?? false;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
