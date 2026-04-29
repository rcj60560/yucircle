import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../providers/auth_controller.dart';
import '../../utils/constants.dart';
import '../../widgets/duo_button.dart';

class SetupProfilePage extends StatefulWidget {
  const SetupProfilePage({super.key});

  @override
  State<SetupProfilePage> createState() => _SetupProfilePageState();
}

class _SetupProfilePageState extends State<SetupProfilePage> {
  final AuthController _auth = Get.find();
  final _nicknameController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _onDone() async {
    _auth.nickname.value = _nicknameController.text.trim();
    final ok = await _auth.setupProfile();
    if (ok) {
      Get.offAllNamed('/main');
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              const Text(
                '完善你的资料 🏸',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ).animate().fadeIn().slideY(begin: 0.1, end: 0),

              const SizedBox(height: 8),

              const Text(
                '让球友更了解你',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ).animate(delay: 150.ms).fadeIn(),

              const SizedBox(height: 40),

              // 昵称
              const Text(
                '你的昵称',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ).animate(delay: 200.ms).fadeIn(),

              const SizedBox(height: 10),

              TextField(
                controller: _nicknameController,
                maxLength: 20,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: '给自己起个球场绰号',
                  counterText: '',
                ),
                onChanged: (v) => _auth.nickname.value = v,
              ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.05, end: 0),

              const SizedBox(height: 32),

              // 技术等级
              const Text(
                '你的技术等级',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ).animate(delay: 300.ms).fadeIn(),

              const SizedBox(height: 12),

              ...Constants.badmintonLevels.asMap().entries.map((entry) {
                final i = entry.key;
                final level = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Obx(() {
                    final selected = _auth.selectedLevel.value == level['value'];
                    return GestureDetector(
                      onTap: () => _auth.selectedLevel.value = level['value']!,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.primary.withOpacity(0.08) : AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected ? AppTheme.primary : AppTheme.border,
                            width: selected ? 2.5 : 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              level['label']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: selected ? AppTheme.primary : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                level['desc']!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.primary,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ).animate(delay: Duration(milliseconds: 350 + i * 80)).fadeIn().slideX(begin: 0.1, end: 0);
              }),

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

              Obx(() => DuoButton(
                    label: '进入羽圈 🚀',
                    isLoading: _auth.step.value == AuthStep.settingProfile,
                    onTap: _onDone,
                  )).animate(delay: 700.ms).fadeIn().slideY(begin: 0.1, end: 0),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
