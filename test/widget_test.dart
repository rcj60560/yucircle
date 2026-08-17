// 冒烟测试：应用根组件可构建，Splash 自动导航的两条路径均有覆盖
// （替换自 Flutter 模板计数器测试 —— 该测试引用了不存在的 MyApp，
//   在本仓库中自创建以来从未通过。）

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yucircle/config/dev_flags.dart';
import 'package:yucircle/main.dart';
import 'package:yucircle/pages/auth/login_page.dart';
import 'package:yucircle/pages/main/main_page.dart';

void main() {
  setUp(() {
    // SplashPage 会读 SharedPreferences 判断登录态，打桩避免插件缺失。
    SharedPreferences.setMockInitialValues({});
    // 默认验证真实跳转（未登录→登录页）；调试绕过路径由专门用例覆盖。
    devBypassLogin = false;
  });

  testWidgets('未登录 → Splash 自动跳到登录页', (WidgetTester tester) async {
    await tester.pumpWidget(const YuCircleApp());
    expect(find.byType(MaterialApp), findsOneWidget);

    // 推进 2.2s 的 Splash 自动跳转延时，避免测试结束时残留 Timer。
    await tester.pump(const Duration(milliseconds: 2500));
    // 再推进足够时间，让登录页的 staggered 入场动画（最长 700ms 延时）全部完成。
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('调试绕过登录 → Splash 直进主页，Tab1 为羽联', (WidgetTester tester) async {
    devBypassLogin = true;

    await tester.pumpWidget(const YuCircleApp());
    // Splash 2.2s 延时 + 跳转；主页数据加载为异步，多泵一拍让它走完。
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.byType(MainPage), findsOneWidget);
    // 底部导航 Tab1 文案（球馆→羽联 的导航重排契约）
    expect(find.text('羽联'), findsOneWidget);

    // 社区页在测试环境加载失败会弹 GetX Snackbar，其动画 Ticker
    // 必须在收尾前关闭并泵完退出动画，否则 teardown 抛 Ticker 泄漏异常。
    Get.closeAllSnackbars();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  });
}
