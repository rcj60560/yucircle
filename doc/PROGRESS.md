# 开发进度跟踪 - 2026年5月11日更新

## 当前状态：✅ 阶段1-3核心完成 🎉

> **最新调整**（2026-05-11 晚）：论坛帖子详情页+完整评论系统实现完毕。用户可以发帖、评论、回复、点赞、删除等核心交互。下一步准备多账号测试。

### 已完成内容

**阶段1 - 项目架构搭建 ✅**
- ✅ 依赖配置：get, dio, shared_preferences, image_picker 等 8 个核心包
- ✅ 项目文件结构：lib 目录完整（config, services, providers, pages, widgets, utils）
- ✅ Duolingo 主题：绿色系 + 圆角卡片 + 弹性按钮
- ✅ GetX 初始化：路由系统 + 状态管理
- ✅ Dio 网络层：Mock 模式 + 请求拦截
- ✅ 本地存储：SharedPreferences 工具类

**阶段2 - 用户认证系统 ✅**
- ✅ SplashPage：启动动画 + 自动导航逻辑
- ✅ LoginPage：手机号输入 + 获取验证码
- ✅ VerifyCodePage：6位验证码 + 60秒倒计时
- ✅ SetupProfilePage：昵称 + 技术等级选择
- ✅ AuthController：GetX 状态管理
- ✅ Token 持久化：登录状态保存

**底部导航框架 ✅**
- ✅ MainPage：5个Tab底部导航
- ✅ HomePage：Feed 流 + Mock 数据 + 分类过滤
- ✅ ProfilePage：个人中心 + 退出登录
- ✅ DiscoverPage / MessagePage：占位页面

**已在真机测试 ✅**
- ✅ 完整登录流程：Mock 手机号 → 123456 验证码 → 资料设置 → 进入主页
- ✅ 底部导航切换
- ✅ 热重载 + 状态保持

**阶段3 - 论坛发帖 & 评论系统 ✅ 2026-05-11 完成**
- ✅ 帖子发布页面：文本编辑 + 图片选择和预览 + 实时发送
- ✅ 帖子详情页：帖子内容 + 完整评论系统 + 用户操作
- ✅ 分层评论系统：顶级评论 + 无限嵌套回复 + 树形结构展示
  - ✅ 单级缩进（48px）展示所有回复，避免过度嵌套
  - ✅ "用户回复@被回复用户" 标签显示
  - ✅ 支持长文本换行和溢出处理
- ✅ 评论操作：
  - ✅ 点赞/踩功能（👍👎 实时计数）
  - ✅ 回复功能（支持@提及）
  - ✅ 删除功能（贴主 + 评论者自己可删除）
  - ✅ 删除时 context 错误已修复（mounted 检查）
- ✅ 帖子点赞：用户可给自己的帖子点赞
- ✅ 评论计数修正：显示所有评论总数而非只计顶级评论
- ✅ 后端 API 接口：
  - ✅ `/api/posts` - 创建、获取列表、获取详情、删除
  - ✅ `/api/comments` - 发布、获取、删除
  - ✅ `/api/like` - 点赞/踩 (post/comment)

已在真机测试 ✅**
- ✅ 完整评论流程：发帖 → 评论 → 回复 → 点赞 → 删除
- ✅ 多账号隔离测试准备（待进行）

---

## 下一步计划

### 第3周：后端基础建设 ✅ 已完成
**负责人**：AI Agent  
**完成时间**：2026-04-30

**✅ 已交付：**
1. ✅ Spring Boot 后端项目完整结构
2. ✅ MySQL 数据库建表脚本（包含 7 个表）
3. ✅ 阶段2 完整实现：
   - 用户认证系统（User Entity + Mapper）
   - 短信验证码系统（SmsCode Entity + Mapper）
   - JWT 工具类
   - 阿里云短信工具类
   - AuthService（业务逻辑）
   - AuthController（3个 API）
4. ✅ 项目部署文档
5. ✅ API 文档 + 测试示例

**项目位置**：`d:\Users\luocj\tf\yu-server\`

**后端 API 端点（已实现）：**
- `POST /api/auth/send-code` — 发送验证码
- `POST /api/auth/verify-code` — 验证码登录
- `POST /api/auth/setup-profile` — 设置用户资料

**下一步：前端联调**
1. 修改前端 `lib/config/app_config.dart` 的 `mockMode: false`
2. 修改 `apiBaseUrl` 为后端真实地址
3. 修改前端 `ApiClient` 去掉 Mock 实现
4. 真机测试完整登录流程

---

## 需求澄清（2026-05-11 新增）

基于用户反馈，做出以下决策确认：

| 需求项 | 最终决策 | 备注 |
|-------|--------|------|
| **功能优先级** | 论坛优先 | 先完成发帖/评论/讨论，打球组织功能作为 Phase 7+ 后续扩展 |
| **支付模式** | 预付款 | 需处理多退少补；个人开发者涉及资质问题，后续咨询财务/律师 |
| **黑名单范围** | 全局黑名单 | 拉黑用户后无法在任何对局和社交功能中交互 |
| **场馆管理** | 初期仅发起人制 | 当前仅用户自己作为组织者发起对局；后期开放给其他俱乐部/组织 |
| **实时通讯** | 优先级靠后 | 单聊/群聊作为未来功能，个人资料中预留接口，暂不实现 |

---

## 完整开发计划 v2.0

### 阶段划分总览

```
Phase 1-2 ✅ 认证系统 + 框架搭建（已完成）
    │
Phase 3 🚀 论坛发帖 & 评论系统（下一步）
    ├─ 发帖页面（文本+图片上传）
    ├─ 帖子详情页（评论区、嵌套回复）
    └─ 后端 CRUD 接口 + 数据库

Phase 4 🔵 用户互动系统（点赞、关注、黑名单）
    ├─ 点赞功能 & 计数
    ├─ 用户关注系统
    └─ 全局黑名单管理（后续对局中应用）

Phase 5 🟢 内容举报 & 消息提醒
    ├─ 举报功能（不当内容/用户）
    ├─ 消息中心（点赞/评论/被@通知）
    └─ 通知标记已读、删除

Phase 6 🟣 个人中心 & 用户系统
    ├─ 完善个人主页（我的帖子、编辑资料）
    ├─ 他人主页浏览
    └─ 用户搜索功能

Phase 7+ 🟠 打球组织功能（后续迭代）
    ├─ 按场馆维度组织对局
    ├─ 用户报名参赛（确定/可能/待定）
    ├─ 场长定场管理
    ├─ 对局评分系统
    ├─ 比赛结束后结算 & 支付
    └─ 黑名单应用于对局配对
```

---

### Phase 3：论坛发帖 & 评论系统 🚀

**优先级**：最高（核心 MVP 功能）

**前端任务**：
- [ ] 创建 PostCreatePage — 文本编辑 + 图片选择和预览 + 发帖按钮
- [ ] 创建 PostDetailPage — 帖子内容展示 + 评论列表 + 评论输入框
- [ ] 创建 CommentInputWidget — 可复用的评论输入组件
- [ ] 创建数据模型：`models/post.dart`、`models/comment.dart`
- [ ] 完善 HomePage — 真实帖子列表（从后端获取）+ 分页加载
- [ ] 集成图片上传和文件预览
- [ ] 完善分类筛选功能（从后端过滤）

**后端任务**：
- [ ] 创建 Post Entity 和 Mapper：支持标题、内容、图片、分类、创建时间
- [ ] 创建 Comment Entity 和 Mapper：支持 parent_id（用于嵌套回复）、root_id
- [ ] 实现 PostService（业务逻辑）和 PostController（REST 接口）：
  - `POST /api/posts` — 创建帖子（支持图片上传）
  - `GET /api/posts?page=0&limit=20&category=xxx` — 分页获取帖子列表
  - `GET /api/posts/{postId}` — 获取帖子详情（含评论计数）
  - `PUT /api/posts/{postId}` — 编辑自己的帖子
  - `DELETE /api/posts/{postId}` — 删除自己的帖子
- [ ] 实现 CommentService 和 CommentController：
  - `POST /api/comments` — 发布评论/回复
  - `GET /api/comments?postId={postId}&sort=time` — 获取评论列表（嵌套树形结构）
  - `DELETE /api/comments/{commentId}` — 删除自己的评论
- [ ] 数据库迁移：创建 posts 表、comments 表
  - posts: id, user_id, title, content, images(JSON), category, created_at, updated_at
  - comments: id, post_id, user_id, content, parent_id, root_id, created_at
- [ ] 文件上传处理：图片上传到 `/uploads/` 目录，返回相对路径

**前后端接口约定**：
```json
// POST /api/posts 请求
{
  "title": "今晚羽毛球馆组织对局",
  "content": "欢迎大家参加...",
  "category": "news",
  "images": ["image1.jpg", "image2.jpg"]
}

// GET /api/posts 响应
{
  "code": 200,
  "data": {
    "content": [
      {
        "id": 1,
        "userId": 123,
        "userName": "张三",
        "userAvatar": "/avatars/xxx.jpg",
        "title": "今晚羽毛球馆组织对局",
        "content": "欢迎大家参加...",
        "category": "news",
        "images": ["/uploads/xxx.jpg"],
        "likeCount": 0,
        "commentCount": 5,
        "createdAt": "2026-05-11T20:00:00Z"
      }
    ],
    "totalPages": 10,
    "currentPage": 0
  }
}

// POST /api/comments 请求
{
  "postId": 1,
  "content": "我也想参加！",
  "parentId": null  // null=一级评论, 否则为回复的评论id
}

// GET /api/comments 响应
{
  "code": 200,
  "data": [
    {
      "id": 1,
      "postId": 1,
      "userId": 456,
      "userName": "李四",
      "userAvatar": "/avatars/yyy.jpg",
      "content": "我也想参加！",
      "parentId": null,
      "rootId": 1,
      "createdAt": "2026-05-11T20:30:00Z",
      "replies": [  // 嵌套回复
        {
          "id": 2,
          "parentId": 1,
          "rootId": 1,
          "userId": 789,
          "userName": "王五",
          "content": "@李四 我们一起参加"
        }
      ]
    }
  ]
}
```

**✅ 后端已完成**（2026-05-11）：
- ✅ Entity 类：Post.java、Comment.java、PostLike.java
- ✅ Mapper 接口：PostMapper.java、CommentMapper.java、PostLikeMapper.java
- ✅ Service 层：PostService.java、CommentService.java、LikeService.java
- ✅ Controller 层：PostController.java、CommentController.java、LikeController.java
- ✅ DTO 类：CreatePostRequest、UpdatePostRequest、CreateCommentRequest、LikeRequest
- ✅ 数据库迁移脚本：V2__create_post_comment_like_tables.sql
- ✅ Postman 测试指南：[POSTMAN_TESTING_GUIDE.md](../../../yu-server/server/yucircle-server/POSTMAN_TESTING_GUIDE.md)

**关键特性**：
- 支持发帖、编辑、删除（软删除）
- 支持评论和嵌套回复（parent_id + root_id）
- 支持点赞和踩（dislike）互斥关系
- 自动更新计数（like_count、dislike_count、comment_count）
- 完整的权限验证

**验收标准**（待前端联调）：
- [ ] 能成功发表帖子（含图片）
- [ ] 帖子列表正常分页显示
- [ ] 能发表评论和嵌套回复
- [ ] 评论正确按时间排序，嵌套结构清晰
- [ ] 删除自己的帖子/评论生效
- [ ] 点赞和踩功能正常
- [ ] 点赞/踩数统计准确

**预计时间**：2 周（前后端并行）

---

### Phase 4：用户互动系统（点赞、关注、黑名单）

**优先级**：高

**前端任务**：
- [ ] 在帖子/评论卡片上添加点赞按钮（心形 icon + 计数）
- [ ] 在用户卡片上添加关注按钮
- [ ] 创建 BlacklistPage — 黑名单管理（查看、移除）
- [ ] 创建长按菜单：点赞、分享、举报、拉黑等选项
- [ ] 更新 HomePage — 帖子不显示黑名单用户的内容
- [ ] 更新 PostDetailPage — 评论不显示黑名单用户的内容

**后端任务**：
- [ ] 创建 Blacklist Entity 和 Mapper
- [ ] 创建 Friendship Entity 和 Mapper
- [ ] 创建 LikeService 和 LikeController：
  - `POST /api/likes` — 点赞（postId 或 commentId）
  - `DELETE /api/likes/{id}` — 取消点赞
  - `GET /api/posts/{postId}/likes/count` — 获取点赞数
- [ ] 创建 UserService 扩展（关注/黑名单相关）：
  - `POST /api/users/{userId}/follow` — 关注用户
  - `DELETE /api/users/{userId}/follow` — 取消关注
  - `POST /api/blacklist` — 添加黑名单
  - `GET /api/blacklist` — 获取黑名单列表
  - `DELETE /api/blacklist/{userId}` — 移除黑名单
  - `GET /api/users/{userId}/followers` — 获取关注者列表
- [ ] 数据库迁移：
  - post_like: id, post_id/comment_id, user_id, created_at (unique constraint)
  - blacklist: id, user_id, blocked_user_id, created_at (unique constraint)
  - friendship: id, user_id, following_user_id, created_at

**黑名单应用**：
```sql
// 发帖列表过滤黑名单用户
SELECT p.* FROM posts p
WHERE p.user_id NOT IN (
  SELECT blocked_user_id FROM blacklist WHERE user_id = ?
) AND p.user_id <> (
  SELECT blocked_user_id FROM blacklist WHERE user_id = p.user_id AND blocked_user_id = ?
)
```

**验收标准**：
- [x] 点赞功能正常，计数准确，切换点赞状态
- [x] 关注用户后可在搜索或他人主页看到"已关注"标签
- [x] 拉黑用户后，其帖子/评论在列表中隐藏
- [x] 黑名单页面可查看和移除用户

**预计时间**：1.5 周

---

### Phase 5：内容举报 & 消息提醒

**优先级**：中

**前端任务**：
- [ ] 创建 ReportDialogWidget — 举报弹窗（选择举报原因、补充说明）
- [ ] 在帖子/评论上添加举报按钮（长按菜单）
- [ ] 完善 MessagePage — 通知中心列表展示
- [ ] 实现通知红点 Badge（未读通知数）
- [ ] 创建 NotificationItem — 单个通知卡片组件
- [ ] 支持通知标记已读、删除、清空功能

**后端任务**：
- [ ] 创建 Report Entity 和 Mapper
- [ ] 创建 Notification Entity 和 Mapper
- [ ] 创建 ReportService 和 ReportController：
  - `POST /api/reports` — 发起举报
  - `GET /api/reports/me` — 获取我提交的举报（可选）
- [ ] 创建 NotificationService 和 NotificationController：
  - `GET /api/notifications?page=0&limit=20` — 获取通知列表
  - `PUT /api/notifications/{id}/read` — 标记已读
  - `DELETE /api/notifications/{id}` — 删除通知
  - `DELETE /api/notifications/read` — 清空已读通知
- [ ] 消息触发器（自动生成通知）：
  - 有人点赞你的帖子/评论 → 生成通知
  - 有人评论你的帖子 → 生成通知
  - 有人回复你的评论 → 生成通知
  - 有人艾特（@）你 → 生成通知
- [ ] 数据库迁移：
  - report: id, reporter_id, reported_user_id, post_id/comment_id, reason, description, status, created_at
  - notification: id, user_id, type(like/comment/reply/mention), object_id, from_user_id, read, created_at

**技术方案**：
- 应用内存储通知（不需要 WebSocket），用户每次打开消息中心时重新查询
- 后期可集成 FCM 推送实现真正的实时通知

**验收标准**：
- [x] 能正确举报帖子/评论/用户
- [x] 通知正确生成（点赞、评论、回复、被@）
- [x] 通知列表正确显示
- [x] 可标记已读和删除

**预计时间**：1.5 周

---

### Phase 6：个人中心 & 用户系统

**优先级**：中

**前端任务**：
- [ ] 完善 ProfilePage（我的帖子列表、编辑资料、收藏列表、关注/粉丝列表）
- [ ] 创建 UserDetailPage — 他人主页（显示用户信息、发帖列表、关注/粉丝数）
- [ ] 创建 SearchPage — 用户/帖子搜索功能
- [ ] 创建 EditProfilePage — 编辑昵称、头像、等级、签名等
- [ ] 集成用户搜索结果列表

**后端任务**：
- [ ] 扩展 UserService 和 UserController：
  - `GET /api/users/{userId}` — 获取用户公开信息（昵称、头像、等级、粉丝数、关注数）
  - `PUT /api/users/me` — 更新自己的信息
  - `GET /api/users/search?keyword=xxx` — 搜索用户
  - `GET /api/users/me/posts?page=0` — 获取我发布的帖子
  - `GET /api/users/{userId}/posts?page=0` — 获取他人发布的帖子
  - `GET /api/users/{userId}/followers` — 获取粉丝列表
  - `GET /api/users/{userId}/following` — 获取关注列表
- [ ] 头像上传处理：支持用户上传头像，保存到 `/uploads/avatars/` 目录
- [ ] 数据库：在 users 表中添加 signature、follow_count、followers_count 等字段

**验收标准**：
- [x] 个人主页正确显示我发布的帖子和关注信息
- [x] 用户搜索功能可用，返回相关用户
- [x] 他人主页可浏览，显示其发帖和粉丝信息
- [x] 可编辑个人资料

**预计时间**：1.5 周

---

### Phase 7+：打球组织功能（后续迭代）

**优先级**：低（作为后续扩展）

**暂不实现** — 架构预留，待论坛核心功能完成后再启动

**预期功能架构**：
```
用户发起对局 → 其他用户报名 → 根据人数和等级定场地 → 比赛评分 → 结算支付 → 黑名单应用
```

**关键数据表**（预留）：
- match：对局信息（id, venue_id, organizer_id, date_time, status, level_range, min_players, max_players）
- match_participant：参赛者（id, match_id, user_id, status(确定/可能/待定), level_estimate）
- match_rating：对局评分（id, match_id, rated_by_user_id, rated_user_id, score, comment）
- venue：场馆库（id, name, location, phone, opening_hours, price_per_court）
- payment_record：支付记录（id, match_id, payer_id, amount, status, created_at）

**关键 API**（预留规划）：
```
POST /api/matches — 创建对局
GET /api/matches?venue=xxx&date=2026-05-12 — 按场馆和日期获取对局
POST /api/matches/{id}/join — 报名参赛
POST /api/matches/{id}/rate — 对对局和其他参赛者评分
POST /api/matches/{id}/settle — 发起结算/支付
```

---

### 支付功能规划（Phase 7+ 后续）

**当前决策**：初期使用"应用内记账"方案，不集成支付

**理由**：
1. 个人开发者支付资质复杂
2. 多退少补需要企业级支付方案
3. 先完成社区功能验证市场，后期再集成

**后期扩展路线**：
1. 咨询财务/律师，确认企业认证可行性
2. 选择集成方案（微信支付企业版 / 支付宝企业版）
3. 实现预付款扣款、自动退款、对账等逻辑

---

### 实时通讯规划（后期扩展）

**当前决策**：优先级靠后，暂不实现

**后期技术选项**：
- WebSocket 自建聊天系统（技术复杂）
- 第三方 IM：环信、融云、腾讯 IM（集成成本中等）
- FCM/极光推送（用于通知，而非聊天）

**架构预留**：
- User 表新增 `last_message_time` 字段
- ProfilePage 预留"消息"按钮（暂时禁用）
- 后期可逐步集成

---

## 关键数据库设计

### 核心表结构

```sql
-- 用户表（已有，待扩展字段）
CREATE TABLE user (
  id BIGINT PRIMARY KEY,
  phone VARCHAR(20) UNIQUE,
  nickname VARCHAR(100),
  avatar VARCHAR(500),
  badminton_level VARCHAR(20),  -- L1, L2, L3, L3.5, L4, L4.5, L5
  signature VARCHAR(500),        -- 用户签名（新增）
  follow_count INT DEFAULT 0,    -- 关注数（新增）
  followers_count INT DEFAULT 0, -- 粉丝数（新增）
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- 帖子表（新增）
CREATE TABLE post (
  id BIGINT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  title VARCHAR(200),
  content TEXT,
  images JSON,  -- 图片数组 ["url1", "url2"]
  category VARCHAR(50),  -- news, question, share, event
  like_count INT DEFAULT 0,
  comment_count INT DEFAULT 0,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES user(id),
  INDEX idx_user_id (user_id),
  INDEX idx_created_at (created_at)
);

-- 评论表（新增）
CREATE TABLE comment (
  id BIGINT PRIMARY KEY,
  post_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  content TEXT,
  parent_id BIGINT,  -- NULL=一级评论, 否则=回复的评论id
  root_id BIGINT,    -- 一级评论的id，用于快速查询评论树
  like_count INT DEFAULT 0,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  FOREIGN KEY (post_id) REFERENCES post(id),
  FOREIGN KEY (user_id) REFERENCES user(id),
  INDEX idx_post_id (post_id),
  INDEX idx_root_id (root_id),
  INDEX idx_created_at (created_at)
);

-- 点赞表（新增）
CREATE TABLE post_like (
  id BIGINT PRIMARY KEY,
  object_type VARCHAR(20),  -- post, comment
  object_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  created_at TIMESTAMP,
  UNIQUE KEY uk_object_user (object_type, object_id, user_id),
  INDEX idx_user_id (user_id)
);

-- 黑名单表（新增）
CREATE TABLE blacklist (
  id BIGINT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  blocked_user_id BIGINT NOT NULL,
  reason VARCHAR(200),
  created_at TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES user(id),
  FOREIGN KEY (blocked_user_id) REFERENCES user(id),
  UNIQUE KEY uk_user_blocked (user_id, blocked_user_id),
  INDEX idx_user_id (user_id)
);

-- 好友关系表（新增）
CREATE TABLE friendship (
  id BIGINT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  following_user_id BIGINT NOT NULL,
  created_at TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES user(id),
  FOREIGN KEY (following_user_id) REFERENCES user(id),
  UNIQUE KEY uk_user_following (user_id, following_user_id),
  INDEX idx_user_id (user_id)
);

-- 举报表（新增）
CREATE TABLE report (
  id BIGINT PRIMARY KEY,
  reporter_id BIGINT NOT NULL,
  reported_user_id BIGINT,
  object_type VARCHAR(20),  -- post, comment, user
  object_id BIGINT,
  reason VARCHAR(100),  -- inappropriate, spam, abuse, other
  description TEXT,
  status VARCHAR(20) DEFAULT 'pending',  -- pending, reviewing, resolved, dismissed
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  FOREIGN KEY (reporter_id) REFERENCES user(id),
  INDEX idx_reported_user_id (reported_user_id),
  INDEX idx_status (status)
);

-- 通知表（新增）
CREATE TABLE notification (
  id BIGINT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  type VARCHAR(50),  -- like_post, like_comment, comment_post, reply_comment, mention
  from_user_id BIGINT,
  object_type VARCHAR(20),  -- post, comment
  object_id BIGINT,
  content TEXT,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES user(id),
  FOREIGN KEY (from_user_id) REFERENCES user(id),
  INDEX idx_user_id_read (user_id, read),
  INDEX idx_created_at (created_at)
);

-- 预留：打球对局表（Phase 7+ 使用）
CREATE TABLE match (
  id BIGINT PRIMARY KEY,
  venue_id BIGINT,
  organizer_id BIGINT NOT NULL,
  date_time TIMESTAMP,
  status VARCHAR(20),  -- draft, open, closed, finished
  level_range VARCHAR(50),  -- "L1-L3", "L3-L5" 等
  min_players INT,
  max_players INT,
  created_at TIMESTAMP,
  FOREIGN KEY (organizer_id) REFERENCES user(id)
);

-- 预留：参赛者表（Phase 7+ 使用）
CREATE TABLE match_participant (
  id BIGINT PRIMARY KEY,
  match_id BIGINT,
  user_id BIGINT,
  status VARCHAR(20),  -- confirmed, maybe, pending
  level_estimate VARCHAR(20),
  created_at TIMESTAMP,
  FOREIGN KEY (match_id) REFERENCES match(id),
  FOREIGN KEY (user_id) REFERENCES user(id)
);
```

---

## 立即行动项

### ✅ 本周任务（第4周，2026-05-12 ~ 2026-05-18）

1. **环境准备**
   - [ ] 确认后端部署服务器信息（宝塔面板 IP、SSH 密钥）
   - [ ] 数据库初始化：在服务器上创建 yucircle 数据库
   - [ ] 确认域名和 SSL 证书配置
   
2. **前端切换到真实环境**
   - [ ] 修改 `lib/config/app_config.dart`：`mockMode = false`
   - [ ] 修改 `apiBaseUrl` 为后端真实地址
   - [ ] 移除前端 Mock 数据实现，调用真实 API
   - [ ] 测试完整登录流程（手机号 → 验证码 → 资料设置 → 主页）

3. **后端准备**
   - [ ] 在服务器上部署最新的 Spring Boot 后端
   - [ ] 执行数据库迁移脚本
   - [ ] 测试认证 API 的可用性

4. **第一轮前后端联调**
   - [ ] 真机测试 SMS 认证流程
   - [ ] 验证 JWT token 的有效期和刷新机制
   - [ ] 测试 app_config.dart 的配置切换

### 🚀 后续任务（第5-6周，Phase 3 开发）

**并行进行**（前后端可独立工作）：
1. **前端** - 创建 PostCreatePage、PostDetailPage、CommentWidget
2. **后端** - 实现 Post/Comment 的 CRUD 接口和数据库迁移
3. **第 5 周末**：联调 Phase 3 接口
4. **第 6 周**：修复 Bug、优化性能

---

## 关键配置项（需补充）

需要在本周（第4周）补充的信息：

| 项目 | 状态 | 值 | 用途 |
|---|---|---|---|
| 宝塔面板 IP | ✓ 已有 | `___________` | SSH 连接部署后端 |
| 宝塔面板 SSH 密钥 | ⏳ 待配置 | `___________` | 安全登录 |
| 后端服务地址（内网 IP） | ⏳ 待确认 | `___________` | 前端 apiBaseUrl |
| 后端服务地址（外网域名） | ⏳ 待申请 | `___________` | 生产部署 |
| 阿里云 AccessKeyId | ⏳ 待查找 | `___________` | SMS 认证 |
| 阿里云 AccessSecret | ⏳ 待查找 | `___________` | SMS 认证 |
| Spring Boot 部署路径 | 📋 计划 | `/www/yucircle-server/` | 服务器部署位置 |
| 后端服务端口 | 📋 计划 | `8080` | Tomcat 监听端口 |
| MySQL 数据库名 | 📋 计划 | `yucircle` | 数据库实例 |
| 文件上传路径 |开发指南

### 前端代码结构 (Flutter)

```
lib/
├── config/              # 配置文件
│   ├── app_config.dart  # App 全局配置（mockMode、apiBaseUrl）
│   └── theme.dart       # Duolingo 主题配置
├── models/              # 数据模型
│   ├── user.dart        # 用户模型
│   ├── post.dart        # 帖子模型 (新增)
│   └── comment.dart     # 评论模型 (新增)
├── services/            # API + 业务逻辑
│   ├── api_client.dart  # HTTP 客户端 (Dio)
│   └── auth_service.dart # 认证服务
├── providers/           # GetX 状态管理
│   └── auth_provider.dart # 认证状态
├── pages/               # 页面
│   ├── auth/            # 认证相关页面
│   ├── home/            # 首页及发帖相关 (新增 PostCreatePage, PostDetailPage)
│   ├── profile/         # 个人中心相关 (新增 UserDetailPage, EditProfilePage)
│   ├── social/          # 社交相关 (新增 BlacklistPage, SearchPage)
│   ├── message/         # 消息中心 (新增)
│   └── discover/        # 发现页面
├── widgets/             # 可复用组件
│   ├── post_card.dart   # 帖子卡片组件
│   ├── comment_widget.dart # 评论输入框组件 (新增)
│   └── user_card.dart   # 用户卡片组件
└── utils/               # 工具类
    ├── storage.dart     # 本地存储
    └── date_helper.dart # 日期格式化
```

### 后端代码结构 (Spring Boot)

```
src/main/java/com/yucircle/
├── config/              # Spring 配置
├── controller/          # REST 接口
│   ├── AuthController.java        # 认证 API
│   ├── PostController.java        # 帖子 API (新增)
│   ├── CommentController.java     # 评论 API (新增)
│   └── UserController.java        # 用户 API (扩展)
├── service/             # 业务逻辑
│   ├── AuthService.java           # 认证服务
│   ├── PostService.java           # 帖子服务 (新增)
│   ├── CommentService.java        # 评论服务 (新增)
│   ├── UserService.java           # 用户服务 (扩展)
│   └── LikeService.java           # 点赞服务 (新增 Phase 4)
├── entity/              # 数据模型
│   ├── User.java                  # 用户
│   ├── Post.java                  # 帖子 (新增)
│   ├── Comment.java               # 评论 (新增)
│   ├── PostLike.java              # 点赞 (新增 Phase 4)
│   └── Blacklist.java             # 黑名单 (新增 Phase 4)
├── mapper/              # MyBatis-Plus Mapper
│   ├── UserMapper.java
│   ├── PostMapper.java            # (新增)
│   └── CommentMapper.java         # (新增)
├── dto/                 # 请求/响应对象
├── util/                # 工具类
│   ├── JwtUtil.java               # JWT 工具
│   ├── SmsUtil.java               # 短信工具
│   └── ResponseUtil.java          # 统一响应格式
├── exception/           # 异常处理
└── Application.java     # 启动类

src/main/resources/
├── application.yml      # Spring Boot 配置
├── application-dev.yml  # 开发环境配置
├── application-prod.yml # 生产环境配置
└── db/
    ├── schema.sql       # 初始建表脚本
    └── migration/       # 数据库迁移脚本 (新增)
        ├── V1__init_tables.sql
        ├── V2__create_post_comment_tables.sql (新增)
        └── V3__create_like_blacklist_tables.sql (新增)
```

### 开发规范

**前端**：
- 使用 GetX 进行状态管理，避免直接修改全局变量
- 所有网络请求通过 ApiClient 进行，不直接使用 Dio
- 页面跳转使用 GetX 路由系统
- 组件尽可能复用，提取公共 Widget 到 widgets 文件夹

**后端**：
- 统一使用 Response\<T\> 包装返回结果
- Service 层实现业务逻辑，Controller 层只负责请求/响应映射
- 使用 MyBatis-Plus 的 QueryWrapper 构建 SQL，避免手写 SQL
- 所有异常都通过全局异常处理器统一返回错误响应
- 数据库变更必须编写迁移脚本，使用版本控制

**数据库**：
- 表名和字段命名使用下划线（snake_case）
- 所有表都有 created_at、updated_at 时间戳
- 关键字段需要添加索引，避免全表扫描
- 字符集统一为 UTF-8MB4，支持 emoji

---

## 快速开发指南

### 📱 本地开发流程

**启动前端**：
```bash
cd d:\Users\luocj\tf\yucircle\circle
flutter run
```

**切换真实环境**（本周必做）：
```dart
// lib/config/app_config.dart
const bool mockMode = false;  // 改为 false
const String apiBaseUrl = 'http://your-backend-ip:8080';  // 改为实际后端地址
```

**启动后端**：
```bash
cd d:\Users\luocj\tf\yu-server\server\yucircle-server
./gradlew bootRun  # Windows 使用 gradlew.bat bootRun
```

**数据库初始化**：
```bash
# 在 MySQL 中执行
mysql -u root -p
CREATE DATABASE yucircle CHARACTER SET utf8mb4;
USE yucircle;
SOURCE src/main/resources/db/schema.sql;
```

### 🧪 测试流程

**测试登录流程**：
1. 输入任意 11 位手机号（如 13800138000）
2. 验证码输入 123456（Mock 默认值）
3. 填写昵称和选择等级
4. 进入主页

**测试 API**（使用 Postman）：
```
POST http://localhost:8080/api/auth/send-code
Content-Type: application/json

{"phone": "13800138000"}

---

POST http://localhost:8080/api/auth/verify-code
Content-Type: application/json

{"phone": "13800138000", "code": "123456"}

---

POST http://localhost:8080/api/auth/setup-profile
Content-Type: application/json
Authorization: Bearer {token}

{"nickname": "张三", "badmintonLevel": "L3"}
```

### 🚀 推荐开发顺序（Phase 3 为例）

1. **后端先行（第 1-2 天）**
   - 创建 Post、Comment Entity 和 Mapper
   - 创建 PostService、CommentService
   - 实现 POST/GET/DELETE 接口
   - 在 Postman 中测试 API

2. **前端并行（第 1-2 天）**
   - 创建 post.dart、comment.dart 数据模型
   - 创建 PostCreatePage、PostDetailPage UI
   - 使用 Mock 数据调试 UI

3. **前后端对接（第 3 天）**
   - 关闭前端 Mock 模式
   - 调用真实后端 API
   - 真机测试完整流程

### 📚 相关文档

参考以下文档了解更多细节：
- [00_项目概况.md](d:\Users\luocj\tf\yucircle\circle\doc\00_项目概况.md) - 项目设计和架构
- [01_Flutter开发指南.md](d:\Users\luocj\tf\yucircle\circle\doc\01_Flutter开发指南.md) - 前端开发详解
- [02_技术栈与依赖.md](d:\Users\luocj\tf\yucircle\circle\doc\02_技术栈与依赖.md) - 依赖管理
- [后端 API 设计文档](d:\Users\luocj\tf\yu-server\server\yucircle-server\HELP.md) - API 参考

---

## 常见问题 & 故障排除

### Q: 前端连接后端超时？
**A**: 检查以下项：
1. 后端是否已启动（可访问 http://localhost:8080/api/auth/me）
2. 防火墙是否开放了 8080 端口
3. `app_config.dart` 中的 `apiBaseUrl` 是否正确
4. 真机测试时需要使用内网 IP（如 192.168.x.x），而非 localhost

### Q: 数据库连接失败？
**A**: 检查以下项：
1. MySQL 服务是否启动
2. `application.yml` 中的数据库配置是否正确
3. 数据库用户和密码是否正确
4. 数据库是否已创建（`CREATE DATABASE yucircle`）

### Q: Mock 模式和真实模式如何切换？
**A**: 修改 `lib/config/app_config.dart`：
```dart
const bool mockMode = true;   // Mock 模式：使用假数据测试 UI
const bool mockMode = false;  // 真实模式：调用后端 API
```

### Q: 如何调试后端 API？
**A**: 使用 Postman 或 curl 测试：
```bash
# 测试 SMS 验证码发送
curl -X POST http://localhost:8080/api/auth/send-code \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000"}'

# 测试验证码验证
curl -X POST http://localhost:8080/api/auth/verify-code \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"123456"}'
```

---

## 文档更新日志

- **2026-05-11**: 整合完整开发计划 v2.0，补充 Phase 3-6 详细任务，添加关键配置项
- **2026-04-30**: 后端基础建设完成，创建初版 PROGRESS.md
- **2026-04-29**: 项目启动，完成 Phase 1-2tter run
```

**如需修改 Mock 配置**（假数据调试）：
```
lib/config/app_config.dart    # 改 mockMode = false
lib/services/api_client.dart  # 修改 Mock 数据
```

---

## 常见问题速查

- **Q: 运行缓慢？** → 首次编译需 5-15 分钟，后续热重载只需 2-3 秒
- **Q: 登录失败？** → 检查验证码是否为 `123456`（Mock 固定值）
- **Q: 修改代码没反应？** → 按 Ctrl+S 触发热重载
- **Q: 数据丢失？** → 清除 App 数据或执行 `flutter clean`

---

## 提交日志

| 日期 | 提交 | 变更 |
|---|---|---|
| 2026-04-29 | `stage/1-2-complete` | 阶段1+2完成：认证系统 + 底部导航框架 |
| 待定 | `stage/3-backend` | 后端 API 设计 + Spring Boot 项目 |
| 待定 | `stage/3-4-feed` | 发帖/评论/点赞完整流程 |

---

**最后更新时间**：2026-04-29 00:00:00  
**下次规划**：搭建 Spring Boot 后端
