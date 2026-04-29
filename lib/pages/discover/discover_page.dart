import 'package:flutter/material.dart';
import '../../config/theme.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('发现')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🔍', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              '发现功能\n即将上线',
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
