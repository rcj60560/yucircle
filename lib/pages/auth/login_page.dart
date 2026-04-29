import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/duo_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final AuthController _auth = Get.put(AuthController());

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    _auth.phone.value = _phoneController.text.trim();
    final ok = await _auth.sendCode();
    if (ok) {
      Get.toNamed('/verify');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 64),

              // Logo 区域
              const Text('🏸', style: TextStyle(fontSize: 72))
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),

              const SizedBox(height: 20),

              const Text(
                '羽圈',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                  letterSpacing: 3,
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),

              const SizedBox(height: 8),

              const Text(
                '羽毛球爱好者的社区',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                ),
              ).animate(delay: 300.ms).fadeIn(),

              const SizedBox(height: 56),

              // 手机号输入
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  '输入手机号登录',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ).animate(delay: 400.ms).fadeIn().slideX(begin: -0.1, end: 0),
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  '未注册的手机号将自动创建账号',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ).animate(delay: 450.ms).fadeIn(),
              ),

              const SizedBox(height: 24),

              // 手机号输入框
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: const Text(
                      '+86',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0),
                  hintText: '请输入手机号',
                  counterText: '',
                ),
                onChanged: (v) => _auth.phone.value = v,
              ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.1, end: 0),

              const SizedBox(height: 16),

              // 错误信息
              Obx(() => _auth.errorMsg.value.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _auth.errorMsg.value,
                        style: const TextStyle(color: AppTheme.danger, fontSize: 14),
                      ),
                    )
                  : const SizedBox.shrink()),

              const SizedBox(height: 8),

              // 发送验证码按钮
              Obx(() => DuoButton(
                    label: '获取验证码',
                    isLoading: _auth.step.value == AuthStep.sendingCode,
                    onTap: _onNext,
                  )).animate(delay: 600.ms).fadeIn().slideY(begin: 0.1, end: 0),

              const SizedBox(height: 32),

              const Text(
                '登录即代表同意《用户协议》和《隐私政策》',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ).animate(delay: 700.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
