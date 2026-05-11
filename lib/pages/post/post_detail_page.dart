import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../services/api_client.dart';
import '../../utils/storage.dart';

class PostDetailPage extends StatefulWidget {
  final int postId;
  final Map<String, dynamic> post;

  const PostDetailPage({
    super.key,
    required this.postId,
    required this.post,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late List<Map<String, dynamic>> comments = [];
  final TextEditingController _commentController = TextEditingController();
  late final FocusNode _commentFocusNode = FocusNode();
  bool _isLoadingComments = false;
  bool _isSubmittingComment = false;
  int? _replyingToCommentId;
  String? _replyingToUsername;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadComments();
  }

  /// 加载当前用户ID
  Future<void> _loadCurrentUser() async {
    try {
      final userInfo = await StorageManager.getUserInfo();
      if (userInfo != null && userInfo.isNotEmpty) {
        final userId = userInfo['userId'];
        if (userId != null) {
          setState(() {
            _currentUserId = int.tryParse(userId);
          });
        }
      }
    } catch (e) {
      print('加载用户信息失败: $e');
    }
  }

  /// 加载评论列表
  Future<void> _loadComments() async {
    if (_isLoadingComments) return;

    setState(() => _isLoadingComments = true);
    try {
      final response = await ApiClient.getComments(widget.postId);
      
      if (response['code'] == 200) {
        final data = response['data'];
        List<Map<String, dynamic>> commentList = [];
        
        if (data is List) {
          commentList = data
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        }
        
        setState(() {
          comments = commentList;
        });
        print('✅ 评论加载成功: ${comments.length} 条');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载评论失败: ${response['msg']}')),
        );
      }
    } catch (e) {
      print('❌ 加载评论错误: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('加载评论失败，请重试')),
      );
    } finally {
      setState(() => _isLoadingComments = false);
    }
  }

  /// 发表评论
  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入评论内容')),
      );
      return;
    }

    setState(() => _isSubmittingComment = true);
    try {
      final response = await ApiClient.createComment(
        postId: widget.postId,
        content: _commentController.text.trim(),
        parentId: _replyingToCommentId,
        rootId: _replyingToCommentId != null ? _replyingToCommentId : null,
      );

      if (response['code'] == 200) {
        _commentController.clear();
        // 收起键盘
        FocusScope.of(context).unfocus();
        setState(() {
          _replyingToCommentId = null;
          _replyingToUsername = null;
        });
        
        // 重新加载评论
        await _loadComments();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('评论已发表')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发表失败: ${response['msg']}')),
        );
      }
    } catch (e) {
      print('❌ 发表评论错误: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('发表失败，请重试')),
      );
    } finally {
      setState(() => _isSubmittingComment = false);
    }
  }

  /// 删除评论（仅贴主可删）
  Future<void> _deleteComment(int commentId, int commentUserId) async {
    // 检查是否是贴主或评论所有者
    final postUserId = widget.post['userId'];
    if (_currentUserId != postUserId && _currentUserId != commentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('只有贴主或评论者可以删除评论')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除评论'),
        content: const Text('确定要删除这条评论吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                final response = await ApiClient.deleteComment(commentId);
                
                if (mounted) {
                  if (response['code'] == 200) {
                    await _loadComments();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('评论已删除')),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('删除失败: ${response['msg']}')),
                      );
                    }
                  }
                }
              } catch (e) {
                print('❌ 删除评论错误: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('删除失败，请重试')),
                  );
                }
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 点赞/踩评论
  /// 点赞评论
  Future<void> _toggleLike(int commentId, String type) async {
    try {
      final response = await ApiClient.toggleLike(
        objectType: 'comment',
        objectId: commentId,
        type: type,
      );

      if (response['code'] == 200) {
        // 重新加载评论以更新点赞数
        await _loadComments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: ${response['msg']}')),
        );
      }
    } catch (e) {
      print('❌ 切换点赞错误: $e');
    }
  }

  /// 点赞帖子
  Future<void> _togglePostLike() async {
    try {
      final response = await ApiClient.toggleLike(
        objectType: 'post',
        objectId: widget.postId,
        type: 'like',
      );

      if (response['code'] == 200) {
        // 重新加载帖子信息以更新点赞数
        final postResponse = await ApiClient.getPost(widget.postId);
        if (postResponse['code'] == 200) {
          setState(() {
            widget.post['likeCount'] = postResponse['data']['likeCount'] ?? 0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已点赞')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: ${response['msg']}')),
        );
      }
    } catch (e) {
      print('❌ 点赞帖子错误: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('点赞失败，请重试')),
      );
    }
  }

  /// 根据评论ID找到对应的评论
  Map<String, dynamic>? _findCommentById(int commentId) {
    for (var comment in comments) {
      if (comment['id'] == commentId) {
        return comment;
      }
    }
    return null;
  }

  /// 格式化时间
  String _formatTime(String? timeStr) {
    if (timeStr == null) return '未知';
    try {
      final dateTime = DateTime.parse(timeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return '刚刚';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}分钟前';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}小时前';
      } else {
        return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
      }
    } catch (e) {
      return '未知';
    }
  }

  /// 获取用户头像缩写
  String _getAvatarText(String? nickname) {
    if (nickname == null || nickname.isEmpty) return '?';
    return nickname.substring(0, 1).toUpperCase();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '帖子详情',
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // 帖子内容和评论列表
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 帖子卡片
                  _buildPostCard(),
                  
                  // 评论标题 - 显示所有评论总数
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '评论 (${comments.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  // 评论列表
                  if (_isLoadingComments)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: CircularProgressIndicator(),
                    )
                  else if (comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '暂无评论，来发表第一条吧！',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: _buildTopLevelComments(),
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 评论输入框
          _buildCommentInput(),
        ],
      ),
    );
  }

  /// 构建顶级评论列表（只显示parentId=null的评论）
  List<Widget> _buildTopLevelComments() {
    final topLevelComments = comments.where((c) => c['parentId'] == null).toList();
    List<Widget> widgets = [];
    
    for (final comment in topLevelComments) {
      widgets.add(_buildCommentItem(comment, isReply: false));
      // 显示该评论的所有回复
      widgets.addAll(_buildReplyList(comment['id']));
    }
    
    return widgets;
  }

  /// 构建某条评论的回复列表
  List<Widget> _buildReplyList(int parentCommentId, {int depth = 0}) {
    final replies = comments.where((c) => c['parentId'] == parentCommentId).toList();
    List<Widget> widgets = [];
    
    for (final reply in replies) {
      // 所有回复只显示一级缩进，不递归缩进
      widgets.add(_buildCommentItem(reply, isReply: true, depth: 1));
      // 递归显示该回复的回复
      widgets.addAll(_buildReplyList(reply['id'], depth: depth + 1));
    }
    
    return widgets;
  }

  /// 构建帖子卡片
  Widget _buildPostCard() {
    final post = widget.post;
    final avatar = post['avatar'] ?? '';
    final nickname = post['nickname'] ?? '匿名用户';
    final title = post['title'] ?? '';
    final content = post['content'] ?? '';
    final createdAt = post['createdAt'] ?? '';
    final likeCount = post['likeCount'] ?? 0;
    final commentCount = post['commentCount'] ?? 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户信息
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF667EEA),
                child: Text(
                  _getAvatarText(nickname),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      _formatTime(createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 标题
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

          // 内容
          if (content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.black54,
                ),
                maxLines: 10,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // 统计信息
          Row(
            children: [
              GestureDetector(
                onTap: () => _togglePostLike(),
                child: _buildStatItem('👍', likeCount),
              ),
              const SizedBox(width: 24),
              _buildStatItem('💬', commentCount),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建统计信息项
  Widget _buildStatItem(String icon, int count) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// 构建评论项
  Widget _buildCommentItem(Map<String, dynamic> comment, {bool isReply = false, int depth = 0}) {
    final commentId = comment['id'];
    final userId = comment['userId'];
    final nickname = comment['nickname'] ?? comment['userName'] ?? '匿名用户';
    final content = comment['content'] ?? '';
    final createdAt = comment['createdAt'] ?? '';
    final likeCount = comment['likeCount'] ?? 0;
    final dislikeCount = comment['dislikeCount'] ?? 0;
    final parentId = comment['parentId'];

    // 所有回复统一缩进48px，不需要递归缩进
    final leftPadding = isReply ? 48.0 : 0.0;
    final avatarRadius = isReply ? 16.0 : 18.0;
    final fontSize = isReply ? 12.0 : 13.0;
    final contentFontSize = isReply ? 13.0 : 14.0;

    return Padding(
      padding: EdgeInsets.only(left: leftPadding, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 如果是回复，显示"X回复@Y"的标签
          if (isReply && parentId != null)
            Builder(
              builder: (context) {
                final parentComment = _findCommentById(parentId);
                final parentNickname = parentComment?['nickname'] ?? '未知用户';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: nickname,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        TextSpan(
                          text: ' 回复 ',
                          style: TextStyle(
                            fontSize: fontSize,
                            color: Colors.grey,
                          ),
                        ),
                        TextSpan(
                          text: '@$parentNickname',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF667EEA),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // 评论头部
          Row(
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: const Color(0xFFF5576C),
                child: Text(
                  _getAvatarText(nickname),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: avatarRadius * 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isReply)
                      Text(
                        nickname,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    Text(
                      _formatTime(createdAt),
                      style: TextStyle(
                        fontSize: fontSize - 1,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 评论内容 - 支持换行
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              content,
              softWrap: true,
              maxLines: null,
              style: TextStyle(
                fontSize: contentFontSize,
                height: 1.5,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 评论操作
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildActionButton(
                    '👍',
                    likeCount,
                    () => _toggleLike(commentId, 'like'),
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    '👎',
                    dislikeCount,
                    () => _toggleLike(commentId, 'dislike'),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        _replyingToCommentId = commentId;
                        _replyingToUsername = nickname;
                      });
                      // 延迟后请求焦点，确保键盘弹出
                      await Future.delayed(const Duration(milliseconds: 100));
                      if (mounted) {
                        FocusScope.of(context).requestFocus(_commentFocusNode);
                      }
                    },
                    child: Text(
                      '💬 回复',
                      style: TextStyle(
                        fontSize: fontSize,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  // 删除按钮（贴主或评论者可见）
                  if (_currentUserId == widget.post['userId'] || _currentUserId == userId)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: GestureDetector(
                        onTap: () => _deleteComment(commentId, userId),
                        child: Text(
                          '🗑️ 删除',
                          style: TextStyle(
                            fontSize: fontSize,
                            color: Colors.red[600],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton(
    String icon,
    int count,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建评论输入框
  Widget _buildCommentInput() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 回复提示
          if (_replyingToUsername != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Text(
                    '回复 $_replyingToUsername',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF667EEA),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _replyingToCommentId = null;
                        _replyingToUsername = null;
                      });
                    },
                    child: const Text(
                      '✕',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF667EEA),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 输入框
          Row(
            children: [
              Expanded(
                child: TextField(
                  focusNode: _commentFocusNode,
                  controller: _commentController,
                  maxLines: null,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: '说说你的想法...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF667EEA),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    counterText: '',
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _isSubmittingComment ? null : _submitComment,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isSubmittingComment
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '发送',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
