import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/duo_button.dart';

class VerifyCodePage extends StatefulWidget {
  const VerifyCodePage({super.key});

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final AuthController _auth = Get.find();
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitEntered(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    final code = _controllers.map((c) => c.text).join();
    _auth.smsCode.value = code;
    if (code.length == 6) {
      _onVerify();
    }
  }

  Future<void> _onVerify() async {
    FocusScope.of(context).unfocus();
    final ok = await _auth.verifyCode();
    if (ok) {
      if (_auth.isNewUser.value) {
        Get.offAllNamed('/setup');
      } else {
        Get.offAllNamed('/main');
      }
    } else {
      // 清空输入框
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('验证手机号'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              Obx(() => Text(
                    '验证码已发送至\n+86 ${_auth.phone.value}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  )).animate().fadeIn().slideY(begin: 0.1, end: 0),

              const SizedBox(height: 8),

              const Text(
                'Mock 模式下输入 123456 即可',
                style: TextStyle(fontSize: 13, color: AppTheme.accent),
              ).animate(delay: 200.ms).fadeIn(),

              const SizedBox(height: 40),

              // 6位验证码输入框
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (i) => _buildCodeBox(i),
                ),
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1, end: 0),

              const SizedBox(height: 20),

              // 错误信息
              Obx(() => _auth.errorMsg.value.isNotEmpty
                  ? Text(
                      _auth.errorMsg.value,
                      style: const TextStyle(color: AppTheme.danger, fontSize: 14),
                    )
                  : const SizedBox.shrink()),

              const SizedBox(height: 32),

              // 验证按钮
              Obx(() => DuoButton(
                    label: '验证',
                    isLoading: _auth.step.value == AuthStep.verifyingCode,
                    onTap: _onVerify,
                  )).animate(delay: 400.ms).fadeIn(),

              const SizedBox(height: 24),

              // 重新发送
              Center(
                child: Obx(() {
                  final cd = _auth.countdown.value;
                  return TextButton(
                    onPressed: cd == 0 ? () => _auth.sendCode() : null,
                    child: Text(
                      cd > 0 ? '重新发送（${cd}s）' : '重新发送验证码',
                      style: TextStyle(
                        fontSize: 15,
                        color: cd > 0 ? AppTheme.textSecondary : AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
              ).animate(delay: 500.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeBox(int index) {
    return SizedBox(
      width: 48,
      height: 60,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        maxLength: 1,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.border, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2.5),
          ),
          filled: true,
          fillColor: AppTheme.surface,
        ),
        onChanged: (v) => _onDigitEntered(index, v),
      ),
    );
  }
}
