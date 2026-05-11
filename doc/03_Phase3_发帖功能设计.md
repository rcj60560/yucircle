# Phase 3：论坛发帖功能 - 完整设计文档

> **最后更新**：2026-05-11  
> **优先级**：⭐⭐⭐⭐⭐ 核心 MVP 功能  
> **预计时间**：2-3 周（前后端并行）  
> **负责人**：AI Agent + 开发者

---

## 1. 功能概述

### 1.1 核心功能模块

| 功能 | 描述 | 优先级 | 依赖 |
|------|------|-------|------|
| **发帖** | 创建、编辑、删除帖子（支持文本+图片） | ⭐⭐⭐⭐⭐ | 无 |
| **帖子列表** | 分页展示帖子，支持分类/搜索过滤 | ⭐⭐⭐⭐⭐ | 发帖 |
| **帖子详情** | 展示帖子内容，显示评论区 | ⭐⭐⭐⭐⭐ | 发帖 |
| **评论系统** | 一级和嵌套评论，支持回复 | ⭐⭐⭐⭐⭐ | 发帖 |
| **点赞** | 用户可点赞帖子/评论 | ⭐⭐⭐⭐ | 发帖、评论 |
| **踩功能** | 反向点赞，与点赞互斥 | ⭐⭐⭐⭐ | 点赞 |
| **删除功能** | 用户可删除自己的帖子/评论 | ⭐⭐⭐ | 发帖、评论 |

### 1.2 使用流程

```
用户登录 → 进入首页
         ├─ 浏览帖子列表 → 查看帖子详情 → 点赞/踩 → 评论
         └─ 点击"发帖" → 编辑内容+图片 → 提交

评论流程：
  用户在帖子详情页
  ├─ 发表一级评论
  └─ 点击某条评论 → 回复该评论（形成嵌套）
     ├─ 对回复点赞/踩
     └─ 删除自己的回复
```

---

## 2. 数据模型设计

### 2.1 数据库表设计

#### Post（帖子表）

```sql
CREATE TABLE post (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  title VARCHAR(200) NOT NULL,
  content TEXT NOT NULL,
  images JSON,  -- ["url1", "url2", "url3"] 最多5张
  category VARCHAR(50),  -- news, question, share, event, other
  like_count INT DEFAULT 0,
  dislike_count INT DEFAULT 0,
  comment_count INT DEFAULT 0,
  view_count INT DEFAULT 0,
  status VARCHAR(20) DEFAULT 'published',  -- published, draft, deleted
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES user(id),
  INDEX idx_user_id (user_id),
  INDEX idx_category (category),
  INDEX idx_created_at (created_at),
  INDEX idx_status (status)
);
```

#### Comment（评论表）

```sql
CREATE TABLE comment (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  post_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  content TEXT NOT NULL,
  parent_id BIGINT,  -- NULL=一级评论, 非NULL=回复的评论id
  root_id BIGINT,    -- 一级评论的id，用于查询评论树
  like_count INT DEFAULT 0,
  dislike_count INT DEFAULT 0,
  status VARCHAR(20) DEFAULT 'published',  -- published, deleted
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (post_id) REFERENCES post(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES user(id),
  FOREIGN KEY (parent_id) REFERENCES comment(id) ON DELETE CASCADE,
  INDEX idx_post_id (post_id),
  INDEX idx_root_id (root_id),
  INDEX idx_parent_id (parent_id),
  INDEX idx_user_id (user_id),
  INDEX idx_created_at (created_at)
);
```

#### PostLike（点赞表 - 支持 like 和 dislike）

```sql
CREATE TABLE post_like (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  object_type VARCHAR(20) NOT NULL,  -- 'post' 或 'comment'
  object_id BIGINT NOT NULL,  -- post_id 或 comment_id
  user_id BIGINT NOT NULL,
  type VARCHAR(20) NOT NULL,  -- 'like' 或 'dislike'
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES user(id),
  -- 同一用户对同一对象只能有一个状态（like 或 dislike 或都没有）
  UNIQUE KEY uk_object_user (object_type, object_id, user_id),
  INDEX idx_user_id (user_id),
  INDEX idx_object (object_type, object_id)
);
```

### 2.2 数据模型结构图

```
┌─────────────────┐
│      User       │
│   (用户信息)     │
└────────┬────────┘
         │
         ├─── 1:N ──→ Post(帖子)
         │            ├─ title, content, images
         │            ├─ like_count, dislike_count
         │            └─ comment_count
         │
         └─── 1:N ──→ PostLike(点赞)
                      ├─ type: 'like' 或 'dislike'
                      └─ object_type: 'post' 或 'comment'

Post ──────1:N────→ Comment(评论)
                    ├─ parent_id (支持嵌套)
                    ├─ root_id (快速查询评论树)
                    ├─ like_count, dislike_count
                    └─ user_id → User
```

---

## 3. API 接口设计

### 3.1 发帖相关 API

#### 创建帖子 - `POST /api/posts`

**请求**：
```json
{
  "title": "今晚羽毛球馆有组织的对局吗？",
  "content": "我是 L3 水平，想找个人一起去打球，有兴趣的吗？",
  "category": "question",  // news, question, share, event, other
  "images": [
    "file1.jpg",  // 上传的文件名，后端会保存为 /uploads/xxxx.jpg
    "file2.jpg"
  ]
}
```

**响应**：
```json
{
  "code": 200,
  "message": "发帖成功",
  "data": {
    "id": 101,
    "userId": 12,
    "title": "今晚羽毛球馆有组织的对局吗？",
    "content": "我是 L3 水平，想找个人一起去打球，有兴趣的吗？",
    "category": "question",
    "images": ["/uploads/post_20260511_001_1.jpg", "/uploads/post_20260511_001_2.jpg"],
    "likeCount": 0,
    "dislikeCount": 0,
    "commentCount": 0,
    "createdAt": "2026-05-11T20:30:00Z"
  }
}
```

#### 获取帖子列表 - `GET /api/posts`

**请求参数**：
```
GET /api/posts?page=0&limit=20&category=question&search=羽毛球
- page: 分页页码（0开始）
- limit: 每页数量（默认20）
- category: 分类过滤（可选）
- search: 关键词搜索（可选）
```

**响应**：
```json
{
  "code": 200,
  "data": {
    "content": [
      {
        "id": 101,
        "userId": 12,
        "userName": "张三",
        "userAvatar": "/uploads/avatars/user_12.jpg",
        "userLevel": "L3",
        "title": "今晚羽毛球馆有组织的对局吗？",
        "content": "我是 L3 水平，想找个人一起去打球，有兴趣的吗？",
        "category": "question",
        "images": ["/uploads/post_20260511_001_1.jpg"],
        "likeCount": 5,
        "dislikeCount": 1,
        "commentCount": 3,
        "viewCount": 120,
        "createdAt": "2026-05-11T20:30:00Z",
        "currentUserLikeType": null  // "like", "dislike", 或 null（未操作）
      }
    ],
    "totalPages": 15,
    "currentPage": 0,
    "totalElements": 280
  }
}
```

#### 获取帖子详情 - `GET /api/posts/{id}`

**请求**：
```
GET /api/posts/101
```

**响应**：
```json
{
  "code": 200,
  "data": {
    "post": {
      "id": 101,
      "userId": 12,
      "userName": "张三",
      "userAvatar": "/uploads/avatars/user_12.jpg",
      "userLevel": "L3",
      "title": "今晚羽毛球馆有组织的对局吗？",
      "content": "我是 L3 水平，想找个人一起去打球，有兴趣的吗？",
      "category": "question",
      "images": ["/uploads/post_20260511_001_1.jpg"],
      "likeCount": 5,
      "dislikeCount": 1,
      "commentCount": 3,
      "viewCount": 121,
      "createdAt": "2026-05-11T20:30:00Z",
      "currentUserLikeType": null  // 当前用户的操作状态
    },
    "comments": [
      {
        "id": 201,
        "postId": 101,
        "userId": 20,
        "userName": "李四",
        "userAvatar": "/uploads/avatars/user_20.jpg",
        "userLevel": "L3.5",
        "content": "我也想去！明天可以吗？",
        "parentId": null,
        "rootId": 201,
        "likeCount": 2,
        "dislikeCount": 0,
        "createdAt": "2026-05-11T21:00:00Z",
        "currentUserLikeType": null,
        "replies": [
          {
            "id": 202,
            "postId": 101,
            "userId": 12,
            "userName": "张三",
            "userAvatar": "/uploads/avatars/user_12.jpg",
            "userLevel": "L3",
            "content": "@李四 今晚就有，来不来？",
            "parentId": 201,
            "rootId": 201,
            "likeCount": 1,
            "dislikeCount": 0,
            "createdAt": "2026-05-11T21:05:00Z",
            "currentUserLikeType": "like"
          }
        ]
      }
    ]
  }
}
```

#### 编辑帖子 - `PUT /api/posts/{id}`

**请求**：
```json
{
  "title": "今晚羽毛球馆有组织的对局吗？（已更新）",
  "content": "已找到人，谢谢关注！",
  "category": "news",
  "images": ["/uploads/post_20260511_001_1.jpg"]
}
```

#### 删除帖子 - `DELETE /api/posts/{id}`

**响应**：
```json
{
  "code": 200,
  "message": "删除成功"
}
```

---

### 3.2 评论相关 API

#### 发表评论 - `POST /api/comments`

**请求**：
```json
{
  "postId": 101,
  "content": "我也想参加！",
  "parentId": null  // 一级评论为 null，回复为被回复的评论id
}
```

**响应**：
```json
{
  "code": 200,
  "message": "评论成功",
  "data": {
    "id": 201,
    "postId": 101,
    "userId": 20,
    "userName": "李四",
    "userAvatar": "/uploads/avatars/user_20.jpg",
    "userLevel": "L3.5",
    "content": "我也想参加！",
    "parentId": null,
    "rootId": 201,
    "likeCount": 0,
    "dislikeCount": 0,
    "createdAt": "2026-05-11T21:00:00Z",
    "currentUserLikeType": null
  }
}
```

#### 获取评论列表 - `GET /api/comments?postId=101&sort=time`

**请求参数**：
```
GET /api/comments?postId=101&sort=time
- postId: 必填，帖子id
- sort: 排序方式（time: 时间倒序, likes: 点赞数倒序）
```

**响应**：
```json
{
  "code": 200,
  "data": [
    {
      "id": 201,
      "postId": 101,
      "userId": 20,
      "userName": "李四",
      "userAvatar": "/uploads/avatars/user_20.jpg",
      "userLevel": "L3.5",
      "content": "我也想参加！",
      "parentId": null,
      "rootId": 201,
      "likeCount": 2,
      "dislikeCount": 0,
      "createdAt": "2026-05-11T21:00:00Z",
      "currentUserLikeType": null,
      "replies": [
        {
          "id": 202,
          "postId": 101,
          "userId": 12,
          "userName": "张三",
          "userAvatar": "/uploads/avatars/user_12.jpg",
          "userLevel": "L3",
          "content": "@李四 今晚就有，来不来？",
          "parentId": 201,
          "rootId": 201,
          "likeCount": 1,
          "dislikeCount": 0,
          "createdAt": "2026-05-11T21:05:00Z",
          "currentUserLikeType": "like"
        }
      ]
    }
  ]
}
```

#### 删除评论 - `DELETE /api/comments/{id}`

---

### 3.3 点赞/踩 相关 API

#### 点赞/踩 - `POST /api/likes`

**请求**：
```json
{
  "objectType": "post",  // "post" 或 "comment"
  "objectId": 101,
  "type": "like"  // "like" 或 "dislike"
}
```

**逻辑**：
- 如果用户未操作过，则创建新记录
- 如果用户已点赞，再次点赞会取消；或改为踩
- 如果用户已踩，再次踩会取消；或改为点赞

**响应**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "id": 301,
    "objectType": "post",
    "objectId": 101,
    "type": "like",
    "createdAt": "2026-05-11T21:30:00Z"
  }
}
```

#### 取消点赞/踩 - `DELETE /api/likes/{id}`

**响应**：
```json
{
  "code": 200,
  "message": "取消成功"
}
```

#### 获取点赞/踩 统计 - `GET /api/likes/stats`

**请求参数**：
```
GET /api/likes/stats?objectType=post&objectId=101
```

**响应**：
```json
{
  "code": 200,
  "data": {
    "objectType": "post",
    "objectId": 101,
    "likeCount": 5,
    "dislikeCount": 1,
    "currentUserType": "like"  // null, "like", "dislike"
  }
}
```

---

## 4. 前端开发计划

### 4.1 页面和组件清单

| 页面/组件 | 文件名 | 描述 | 优先级 |
|---------|-------|------|-------|
| **发帖页面** | `post_create_page.dart` | 文本编辑 + 图片上传 | ⭐⭐⭐⭐⭐ |
| **帖子列表** | `home_page.dart` (修改) | 分页列表 + 分类过滤 | ⭐⭐⭐⭐⭐ |
| **帖子详情** | `post_detail_page.dart` | 内容展示 + 评论区 | ⭐⭐⭐⭐⭐ |
| **帖子卡片** | `widgets/post_card.dart` | 列表中的帖子卡片 | ⭐⭐⭐⭐⭐ |
| **评论卡片** | `widgets/comment_card.dart` | 单个评论组件 | ⭐⭐⭐⭐⭐ |
| **评论输入** | `widgets/comment_input_widget.dart` | 评论输入框 | ⭐⭐⭐⭐⭐ |
| **点赞/踩按钮** | `widgets/like_dislike_button.dart` | 点赞踩按钮组件 | ⭐⭐⭐⭐ |

### 4.2 数据模型

**models/post.dart**：
```dart
class Post {
  final int id;
  final int userId;
  final String userName;
  final String userAvatar;
  final String userLevel;
  final String title;
  final String content;
  final List<String> images;
  final String category;
  final int likeCount;
  final int dislikeCount;
  final int commentCount;
  final DateTime createdAt;
  final String? currentUserLikeType;  // null, 'like', 'dislike'
}
```

**models/comment.dart**：
```dart
class Comment {
  final int id;
  final int userId;
  final String userName;
  final String userAvatar;
  final String userLevel;
  final String content;
  final int? parentId;
  final int rootId;
  final int likeCount;
  final int dislikeCount;
  final DateTime createdAt;
  final List<Comment> replies;  // 嵌套回复
  final String? currentUserLikeType;
}
```

### 4.3 GetX 状态管理

**providers/post_provider.dart** (新增)：
```dart
class PostController extends GetxController {
  final posts = <Post>[].obs;
  final isLoading = false.obs;
  final currentPage = 0.obs;
  final selectedCategory = 'all'.obs;
  
  Future<void> fetchPosts({int page = 0, String? category}) async {
    // 获取帖子列表
  }
  
  Future<void> createPost(String title, String content, List<String> images) async {
    // 创建帖子
  }
  
  Future<void> likePost(int postId, String type) async {
    // 点赞/踩
  }
}
```

### 4.4 开发步骤（时间表）

**第 1-2 天**：
- [ ] 创建 PostCreatePage 页面（文本输入 + 图片选择）
- [ ] 创建 PostCard 组件（用于首页列表展示）
- [ ] 创建 LikeDislikeButton 组件（点赞/踩按钮）
- [ ] 创建 post.dart 和 comment.dart 数据模型
- [ ] 创建 PostController GetX 状态管理

**第 2-3 天**：
- [ ] 创建 PostDetailPage 页面
- [ ] 创建 CommentCard 和 CommentInputWidget 组件
- [ ] 完善 HomePage 列表展示
- [ ] 使用 Mock 数据调试 UI

**第 3 天**：
- [ ] 移除 Mock 数据
- [ ] 调用真实后端 API
- [ ] 真机测试完整流程

---

## 5. 后端开发计划

### 5.1 代码文件清单

| 文件 | 类型 | 描述 | 优先级 |
|------|------|------|-------|
| `Post.java` | Entity | 帖子实体 | ⭐⭐⭐⭐⭐ |
| `Comment.java` | Entity | 评论实体 | ⭐⭐⭐⭐⭐ |
| `PostLike.java` | Entity | 点赞实体 | ⭐⭐⭐⭐ |
| `PostMapper.java` | Mapper | 帖子 Mapper | ⭐⭐⭐⭐⭐ |
| `CommentMapper.java` | Mapper | 评论 Mapper | ⭐⭐⭐⭐⭐ |
| `PostLikeMapper.java` | Mapper | 点赞 Mapper | ⭐⭐⭐⭐ |
| `PostService.java` | Service | 帖子业务逻辑 | ⭐⭐⭐⭐⭐ |
| `CommentService.java` | Service | 评论业务逻辑 | ⭐⭐⭐⭐⭐ |
| `LikeService.java` | Service | 点赞业务逻辑 | ⭐⭐⭐⭐ |
| `PostController.java` | Controller | 帖子 REST API | ⭐⭐⭐⭐⭐ |
| `CommentController.java` | Controller | 评论 REST API | ⭐⭐⭐⭐⭐ |
| `LikeController.java` | Controller | 点赞 REST API | ⭐⭐⭐⭐ |
| `V2__create_post_tables.sql` | Migration | 数据库迁移脚本 | ⭐⭐⭐⭐⭐ |

### 5.2 开发步骤（时间表）

**第 1 天**：
- [ ] 创建 Post、Comment、PostLike Entity 类
- [ ] 创建对应的 Mapper 接口
- [ ] 编写数据库迁移脚本

**第 2 天**：
- [ ] 创建 PostService 实现发帖、编辑、删除、列表、详情功能
- [ ] 创建 CommentService 实现评论、回复、删除功能
- [ ] 创建 LikeService 实现点赞/踩逻辑

**第 2-3 天**：
- [ ] 创建 PostController 实现所有 REST API
- [ ] 创建 CommentController 实现评论 API
- [ ] 创建 LikeController 实现点赞 API
- [ ] 使用 Postman 测试所有接口

**第 3 天**：
- [ ] 修复 Bug
- [ ] 性能优化（数据库索引、查询优化）

---

## 6. 前后端对接计划

### 6.1 对接流程

**第 1 周末准备**：
- [ ] 前端 Mock API 测试无误
- [ ] 后端 Postman 测试无误

**第 2 周第 1 天：联调准备**
- [ ] 前端移除 Mock 数据
- [ ] 确认 apiBaseUrl 和后端地址一致
- [ ] 准备测试用例

**第 2 周第 2-3 天：真机测试**
- [ ] [ ] 测试发帖流程
- [ ] 测试帖子列表加载
- [ ] 测试点赞/踩功能
- [ ] 测试评论和回复
- [ ] 测试删除功能

### 6.2 常见问题排查

| 问题 | 排查方法 |
|------|---------|
| 发帖后列表没有新帖子 | 检查前端是否调用了刷新 API；检查后端是否正确保存 |
| 图片上传失败 | 检查 /uploads/ 目录权限；检查文件大小限制 |
| 点赞计数不准确 | 检查数据库是否正确更新 like_count；检查并发问题 |
| 评论嵌套显示错误 | 检查 parent_id 和 root_id 是否正确；检查递归查询逻辑 |

---

## 7. 测试清单

### 7.1 功能测试

**发帖功能**：
- [ ] 能成功发表帖子（文本）
- [ ] 能上传 1-5 张图片
- [ ] 帖子列表正确分页显示
- [ ] 能按分类过滤
- [ ] 能搜索关键词
- [ ] 能编辑自己的帖子
- [ ] 能删除自己的帖子

**评论功能**：
- [ ] 能发表一级评论
- [ ] 能回复评论（嵌套）
- [ ] 评论显示正确的树形结构
- [ ] 能删除自己的评论

**点赞/踩功能**：
- [ ] 能点赞帖子
- [ ] 能对帖子踩
- [ ] 点赞和踩互斥（不能同时点赞和踩）
- [ ] 点赞数和踩数正确更新
- [ ] 能取消点赞/踩
- [ ] 评论也支持点赞/踩

**UI/UX**：
- [ ] 加载中显示骨架屏
- [ ] 操作成功有提示
- [ ] 操作失败有错误提示
- [ ] 图片加载成功且不变形

### 7.2 性能测试

- [ ] 列表加载 < 1s（20 条帖子）
- [ ] 详情页加载 < 1s（包含 100 条评论）
- [ ] 图片上传 < 5s（5MB）
- [ ] 发帖 < 2s

### 7.3 安全性测试

- [ ] 用户只能删除自己的帖子/评论
- [ ] 用户只能编辑自己的帖子
- [ ] SQL 注入防护
- [ ] 图片上传的文件类型限制（仅允许 jpg, png, gif）

---

## 8. 风险评估

| 风险 | 等级 | 应对 |
|------|------|------|
| 图片上传性能 | 中 | 限制文件大小 < 5MB；压缩图片 |
| 评论查询 N+1 | 中 | 使用 LEFT JOIN 一次性查询；加数据库索引 |
| 并发点赞 | 中 | 数据库使用 UNIQUE 约束；应用层使用锁 |
| 大量评论加载 | 低 | 分页加载；懒加载回复 |

---

## 9. 立即行动

### ✅ 本周行动清单（第 4-5 周）

**后端优先**（第 1-2 天）：
- [ ] 创建所有 Entity 类
- [ ] 创建 Mapper 接口
- [ ] 编写数据库迁移脚本
- [ ] 提交 git commit

**前端并行**（第 1-2 天）：
- [ ] 创建 PostCreatePage UI
- [ ] 创建 post.dart、comment.dart 数据模型
- [ ] 创建 PostController

**后端继续**（第 2 天）：
- [ ] 实现 PostService、CommentService、LikeService
- [ ] 创建 PostController、CommentController、LikeController
- [ ] Postman 测试所有接口

**前端继续**（第 2-3 天）：
- [ ] 完善 PostDetailPage
- [ ] 创建所有 Widget 组件
- [ ] 使用 Mock 数据调试 UI

**联调**（第 3 天）：
- [ ] 前端切换到真实 API
- [ ] 真机测试完整流程
- [ ] 修复 Bug

---

## 10. 参考文件

- [PROGRESS.md](PROGRESS.md) - 总体开发进度
- [00_项目概况.md](00_项目概况.md) - 项目设计
- [01_Flutter开发指南.md](01_Flutter开发指南.md) - 前端开发规范
- [02_技术栈与依赖.md](02_技术栈与依赖.md) - 依赖管理

---

**下一步**：选择从后端还是前端开始开发，按照上述计划推进！🚀
