import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../home/home_page.dart';
import '../discover/discover_page.dart';
import '../post/create_post_stub_page.dart';
import '../message/message_page.dart';
import '../profile/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      const DiscoverPage(),
      const SizedBox(), // 发帖用弹窗，不需要页面
      const MessagePage(),
      const ProfilePage(),
    ];
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      // 发帖按钮：跳转到发帖页
      Get.toNamed('/create-post')?.then((result) {
        // 发帖后，切换到首页（用户可手动下拉刷新）
        if (result == true) {
          setState(() => _currentIndex = 0);
        }
      });
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex > 2 ? _currentIndex : (_currentIndex == 2 ? 0 : _currentIndex),
          onTap: _onTabTapped,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: '首页',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_rounded),
              label: '发现',
            ),
            BottomNavigationBarItem(
              icon: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryShadow.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications_rounded),
              label: '消息',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}
