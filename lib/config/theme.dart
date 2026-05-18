import 'package:flutter/material.dart';

/// YuCircle 应用主题配置 - RYMONTADA 蓝色风格
/// 参考设计: https://dribbble.com/shots/26701777-RYMONTADA-Sports-Field-Booking-Tournament-App-UI-Design
class AppTheme {
  // ============ 颜色系统 (RYMONTADA 风格) ============
  static const Color primary = Color(0xFF3C9EFF);        // 主蓝色
  static const Color primaryDark = Color(0xFF2E7FD6);    // 深蓝色（按下效果）
  static const Color primaryLight = Color(0xFF5CB3FF);   // 浅蓝色
  static const Color accent = Color(0xFF4CAF50);         // 强调绿（成功状态）
  static const Color danger = Color(0xFFFF4D4F);         // 错误红
  static const Color warning = Color(0xFFFFA940);        // 警告橙
  static const Color success = Color(0xFF52C41A);        // 成功绿
  
  static const Color surface = Color(0xFFFFFFFF);        // 卡片白
  static const Color background = Color(0xFFF5F7FA);     // 背景浅蓝灰
  static const Color textPrimary = Color(0xFF1F2937);    // 文字深灰
  static const Color textSecondary = Color(0xFF6B7280);  // 文字灰
  static const Color textTertiary = Color(0xFF9CA3AF);   // 文字浅灰
  static const Color border = Color(0xFFE5E7EB);         // 分割线
  static const Color cardShadow = Color(0x0F000000);     // 卡片阴影
  static const Color primaryShadow = Color(0x1F3C9EFF);  // 主蓝色阴影
  // ============ 圆角半径 ============
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  
  // ============ 间距系统 ============
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: accent,
          surface: surface,
          error: danger,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: true,
          shadowColor: Color(0x0F000000),
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: background,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            borderSide: const BorderSide(color: border, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            borderSide: const BorderSide(color: border, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          hintStyle: const TextStyle(color: textTertiary, fontSize: 14),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shadowColor: cardShadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          margin: EdgeInsets.zero,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: primary,
          unselectedItemColor: textTertiary,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          elevation: 8,
          showUnselectedLabels: true,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textSecondary,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textTertiary,
          ),
        ),
      );
  
  // ============ 便捷样式方法 ============
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: const [
      BoxShadow(
        color: cardShadow,
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration buttonDecoration = BoxDecoration(
    color: primary,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: const [
      BoxShadow(
        color: Color(0x1A3C9EFF),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );
}
