import 'package:flutter/material.dart';
import '../../config/theme.dart';

class CreatePostStubPage extends StatelessWidget {
  const CreatePostStubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('发布帖子')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('✏️', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              '发帖功能\n阶段3开发',
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
