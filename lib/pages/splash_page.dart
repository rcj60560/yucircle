import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../utils/storage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    debugPrint('🎯 [Splash] initState 开始');
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    debugPrint('🎯 [Splash] 开始初始化检查');
    // 等动画跑完
    await Future.delayed(const Duration(milliseconds: 2200));
    
    try {
      debugPrint('🔍 [Splash] 检查登录状态...');
      // 尝试读取存储，超时 3 秒
      final loggedIn = await StorageManager.isLoggedIn()
          .timeout(const Duration(seconds: 3), onTimeout: () {
        debugPrint('❌ [Splash] 存储检查超时，跳过');
        return false;
      });
      
      debugPrint('✅ [Splash] 登录状态: $loggedIn');
      
      if (loggedIn) {
        final profileSet = await StorageManager.isProfileSet()
            .timeout(const Duration(seconds: 3), onTimeout: () => false);
        if (profileSet) {
          debugPrint('🚀 [Splash] 跳转到主页');
          Get.offAllNamed('/main');
        } else {
          debugPrint('🚀 [Splash] 跳转到设置资料');
          Get.offAllNamed('/setup');
        }
      } else {
        debugPrint('🚀 [Splash] 跳转到登录页');
        Get.offAllNamed('/login');
      }
    } catch (e) {
      debugPrint('❌ [Splash] 异常: $e');
      debugPrint('🚀 [Splash] 强制跳转到登录页');
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 羽毛球 Logo（用 Text emoji 代替，后续换图片）
            const Text(
              '🏸',
              style: TextStyle(fontSize: 80),
            )
                .animate()
                .scale(
                  begin: const Offset(0.3, 0.3),
                  end: const Offset(1.0, 1.0),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            const Text(
              '羽圈',
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 12),

            const Text(
              '羽毛球爱好者的社区',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 1,
              ),
            )
                .animate(delay: 700.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 60),

            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: Colors.white.withOpacity(0.7),
                strokeWidth: 3,
              ),
            )
                .animate(delay: 900.ms)
                .fadeIn(duration: 300.ms),
          ],
        ),
      ),
    );
  }
}
