import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../providers/auth_controller.dart';
import '../../utils/storage.dart';
import '../../widgets/duo_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, String?> _userInfo = {};

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final info = await StorageManager.getUserInfo();
    setState(() => _userInfo = info);
  }

  @override
  Widget build(BuildContext context) {
    final nickname = _userInfo['nickname'] ?? '球友';
    final level = _userInfo['level'] ?? '-';
    final phone = _userInfo['phone'] ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('我的')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 头像区域
            Container(
              width: double.infinity,
              color: AppTheme.surface,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppTheme.primary.withOpacity(0.15),
                    child: Text(
                      nickname.isNotEmpty ? nickname.substring(0, 1) : '🏸',
                      style: const TextStyle(
                        fontSize: 36,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    nickname,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getLevelLabel(level),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      phone.replaceRange(3, 7, '****'),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 统计数据
            Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _StatItem(label: '帖子', count: '0'),
                  _Divider(),
                  _StatItem(label: '获赞', count: '0'),
                  _Divider(),
                  _StatItem(label: '球友', count: '0'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 菜单项
            Container(
              color: AppTheme.surface,
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.article_outlined,
                    label: '我的帖子',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.favorite_outline_rounded,
                    label: '我的收藏',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.settings_outlined,
                    label: '设置',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: OutlinedButton(
                onPressed: () async {
                  final confirm = await Get.dialog<bool>(
                    AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('退出登录'),
                      content: const Text('确定要退出登录吗？'),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(result: false),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () => Get.back(result: true),
                          child: const Text(
                            '退出',
                            style: TextStyle(color: AppTheme.danger),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final auth = Get.find<AuthController>();
                    await auth.logout();
                    Get.offAllNamed('/login');
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '退出登录',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _getLevelLabel(String level) {
    const map = {
      'beginner': '🐣 入门新手',
      'amateur': '🏸 业余爱好者',
      'intermediate': '⚡ 中级选手',
      'advanced': '🔥 高级选手',
    };
    return map[level] ?? level;
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String count;

  const _StatItem({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: AppTheme.border);
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
