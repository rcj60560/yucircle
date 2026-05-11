import 'package:get/get.dart';
import '../services/api_client.dart';
import '../utils/storage.dart';

enum AuthStep { idle, sendingCode, verifyingCode, settingProfile }

class AuthController extends GetxController {
  final phone = ''.obs;
  final smsCode = ''.obs;
  final nickname = ''.obs;
  final selectedLevel = ''.obs;

  final isLoggedIn = false.obs;
  final isNewUser = false.obs;
  final step = AuthStep.idle.obs;
  final errorMsg = ''.obs;

  // 倒计时
  final countdown = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    isLoggedIn.value = await StorageManager.isLoggedIn();
  }

  // ── 发送验证码 ────────────────────────────────────────────
  Future<bool> sendCode() async {
    if (phone.value.length != 11) {
      errorMsg.value = '请输入正确的手机号';
      return false;
    }
    errorMsg.value = '';
    step.value = AuthStep.sendingCode;
    final res = await ApiClient.sendSmsCode(phone.value);
    step.value = AuthStep.idle;

    if (res['code'] == 200) {  // ← 改为 200（服务端返回码）
      _startCountdown();
      return true;
    }
    errorMsg.value = res['msg'] ?? '发送失败，请重试';
    return false;
  }

  void _startCountdown() {
    countdown.value = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (countdown.value > 0) {
        countdown.value--;
        return true;
      }
      return false;
    });
  }

  // ── 验证验证码 ────────────────────────────────────────────
  Future<bool> verifyCode() async {
    if (smsCode.value.length != 6) {
      errorMsg.value = '请输入 6 位验证码';
      return false;
    }
    errorMsg.value = '';
    step.value = AuthStep.verifyingCode;
    final res = await ApiClient.verifySmsCode(phone.value, smsCode.value);
    step.value = AuthStep.idle;

    if (res['code'] == 200) {  // ← 改为 200
      final data = res['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = data['user'] as Map<String, dynamic>;
      
      await StorageManager.saveToken(token);
      await StorageManager.saveUserInfo(
        userId: user['id'].toString(),
        phone: user['phone'] ?? phone.value,
        nickname: user['nickname'] ?? '',
        level: user['badmintonLevel'] ?? '',
      );
      
      isLoggedIn.value = true;
      return true;
    }
    errorMsg.value = res['msg'] ?? '验证码错误';
    return false;
  }

  // ── 设置资料 ──────────────────────────────────────────────
  Future<bool> setupProfile() async {
    if (nickname.value.trim().isEmpty) {
      errorMsg.value = '请输入昵称';
      return false;
    }
    if (selectedLevel.value.isEmpty) {
      errorMsg.value = '请选择技术等级';
      return false;
    }
    errorMsg.value = '';
    step.value = AuthStep.settingProfile;
    final res = await ApiClient.setupProfile(
      nickname: nickname.value.trim(),
      level: selectedLevel.value,
      phone: phone.value,
    );
    step.value = AuthStep.idle;

    if (res['code'] == 200) {  // ← 改为 200
      final data = res['data'] as Map<String, dynamic>;
      await StorageManager.saveUserInfo(
        userId: data['id'].toString(),
        phone: phone.value,
        nickname: data['nickname'] ?? '',
        level: data['badmintonLevel'] ?? '',
      );
      return true;
    }
    errorMsg.value = '设置失败，请重试';
    return false;
  }

  Future<void> logout() async {
    await StorageManager.clear();
    isLoggedIn.value = false;
    phone.value = '';
    smsCode.value = '';
    nickname.value = '';
    selectedLevel.value = '';
  }
}
