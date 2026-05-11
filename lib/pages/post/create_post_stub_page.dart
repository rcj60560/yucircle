import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../utils/storage.dart';

class CreatePostStubPage extends StatefulWidget {
  const CreatePostStubPage({super.key});

  @override
  State<CreatePostStubPage> createState() => _CreatePostStubPageState();
}

class _CreatePostStubPageState extends State<CreatePostStubPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = '技术交流';
  bool _isLoading = false;
  final _categories = ['技术交流', '球场推荐', '装备讨论', '赛事分享', '找球友', '吐槽大会'];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _publishPost() async {
    if (_titleController.text.trim().isEmpty) {
      Get.snackbar('提示', '请输入标题', backgroundColor: Colors.red);
      return;
    }
    if (_contentController.text.trim().isEmpty) {
      Get.snackbar('提示', '请输入内容', backgroundColor: Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.createPost(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
      );

      if (res['code'] == 200) {
        setState(() => _isLoading = false);  // 加上这行
        Get.snackbar('成功', '发帖成功', backgroundColor: Colors.green);
        await Future.delayed(const Duration(milliseconds: 800));
        Get.back(result: true);  // 返回 true 信号，告诉主页需要刷新
      } else {
        setState(() => _isLoading = false);
        Get.snackbar('失败', res['msg'] ?? '发帖失败', backgroundColor: Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Publish error: $e');
      Get.snackbar('错误', '网络错误: $e', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('发布帖子'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 分类选择
            const Text(
              '选择分类',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 标题输入
            const Text(
              '标题',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              maxLength: 50,
              decoration: InputDecoration(
                hintText: '输入帖子标题（最多50字）',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),

            // 内容输入
            const Text(
              '内容',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 8,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: '分享你的羽毛球故事（最多1000字）',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 24),

            // 发布按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _publishPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                      )
                    : const Text('发布帖子', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
