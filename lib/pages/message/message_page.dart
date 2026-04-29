import 'package:flutter/material.dart';
import '../../config/theme.dart';

class MessagePage extends StatelessWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('消息')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🔔', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              '消息功能\n即将上线',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
