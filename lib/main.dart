import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'config/theme.dart';
import 'pages/splash_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/verify_code_page.dart';
import 'pages/auth/setup_profile_page.dart';
import 'pages/main/main_page.dart';
import 'pages/post/create_post_stub_page.dart';

void main() {
  runApp(const YuCircleApp());
}

class YuCircleApp extends StatelessWidget {
  const YuCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ÓðÈ¦',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const SplashPage()),
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/verify', page: () => const VerifyCodePage()),
        GetPage(name: '/setup', page: () => const SetupProfilePage()),
        GetPage(name: '/main', page: () => const MainPage()),
        GetPage(name: '/create-post', page: () => const CreatePostStubPage()),
      ],
    );
  }
}
