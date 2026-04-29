import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../utils/constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedCategory = 0;
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    final posts = await ApiClient.getPostList(
      category: Constants.postCategories[_selectedCategory],
    );
    setState(() {
      _posts = posts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('🏸 羽圈'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _buildCategoryBar(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: _loadPosts,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _PostCard(
                  post: _posts[i],
                  index: i,
                ),
              ),
            ),
    );
  }

  Widget _buildCategoryBar() {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: Constants.postCategories.length,
        itemBuilder: (context, i) {
          final selected = _selectedCategory == i;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = i);
              _loadPosts();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppTheme.primary : AppTheme.border,
                ),
              ),
              child: Text(
                Constants.postCategories[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final int index;

  const _PostCard({required this.post, required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息行
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primary.withOpacity(0.15),
                  child: Text(
                    (post['nickname'] as String).substring(0, 1),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['nickname'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        post['createdAt'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    post['category'],
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 内容
            Text(
              post['content'],
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 14),

            // 底部点赞/评论行
            Row(
              children: [
                _ActionBtn(
                  icon: Icons.favorite_border_rounded,
                  count: post['likeCount'],
                  color: AppTheme.danger,
                ),
                const SizedBox(width: 20),
                _ActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  count: post['commentCount'],
                  color: AppTheme.textSecondary,
                ),
                const Spacer(),
                const Icon(
                  Icons.more_horiz_rounded,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05, end: 0);
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const _ActionBtn({required this.icon, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
