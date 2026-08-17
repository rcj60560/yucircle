// 最小冒烟测试：应用根组件可以构建并通过 Splash 自动导航。
// （替换自 Flutter 模板计数器测试 —— 该测试引用了不存在的 MyApp，
//   在本仓库中自创建以来从未通过。）

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yucircle/main.dart';
import 'package:yucircle/pages/auth/login_page.dart';

void main() {
  testWidgets('App root builds smoke test', (WidgetTester tester) async {
    // SplashPage 会读 SharedPreferences 判断登录态，打桩避免插件缺失。
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const YuCircleApp());
    expect(find.byType(MaterialApp), findsOneWidget);

    // 推进 2.2s 的 Splash 自动跳转延时，避免测试结束时残留 Timer。
    await tester.pump(const Duration(milliseconds: 2500));
    // 再推进足够时间，让登录页的 staggered 入场动画（最长 700ms 延时）全部完成。
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    // 未登录（mock 为空）→ 应已自动跳转到登录页，应用仍正常构建。
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
