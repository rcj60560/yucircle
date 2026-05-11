import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../utils/constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

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
    try {
      final res = await ApiClient.getPostList(page: 1, limit: 20);
      
      if (res['code'] == 200) {
        final data = res['data'] as Map<String, dynamic>?;
        if (data != null) {
          final recordsRaw = data['records'];
          List<Map<String, dynamic>> records = [];
          
          if (recordsRaw is List) {
            records = recordsRaw.map((item) {
              if (item is Map) {
                return Map<String, dynamic>.from(item);
              }
              return <String, dynamic>{};
            }).toList();
          }
          
          setState(() {
            _posts = records;
            _loading = false;
          });
        } else {
          setState(() => _loading = false);
          Get.snackbar('数据错误', '服务端返回数据格式错误', backgroundColor: Colors.red);
        }
      } else {
        setState(() => _loading = false);
        Get.snackbar('加载失败', res['msg'] ?? '获取帖子列表失败', backgroundColor: Colors.red);
      }
    } catch (e) {
      setState(() => _loading = false);
      Get.snackbar('错误', '网络错误: $e', backgroundColor: Colors.red);
    }
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
    // 安全获取字段值，提供默认值
    final nickname = (post['nickname'] ?? '用户') as String;
    final avatar = (post['avatar'] ?? '') as String;
    final category = (post['category'] ?? '技术交流') as String;
    final content = (post['content'] ?? '') as String;
    final likeCount = (post['likeCount'] ?? 0) as int;
    final commentCount = (post['commentCount'] ?? 0) as int;
    final createdAt = (post['createdAt'] ?? '') as String;
    final postId = (post['id'] ?? 0) as int;
    
    return GestureDetector(
      onTap: () {
        // 点击进入详情页
        Get.toNamed('/post-detail', arguments: {
          'postId': postId,
          'post': post,
        });
      },
      child: Card(
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
                      nickname.isNotEmpty ? nickname.substring(0, 1) : '?',
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
                          nickname,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          createdAt,
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
                      category,
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
                content,
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
                    count: likeCount,
                    color: AppTheme.danger,
                  ),
                  const SizedBox(width: 20),
                  _ActionBtn(
                    icon: Icons.chat_bubble_outline_rounded,
                    count: commentCount,
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
