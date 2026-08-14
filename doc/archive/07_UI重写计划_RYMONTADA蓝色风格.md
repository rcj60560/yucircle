# YuCircle App UI 重写计划 - RYMONTADA 蓝色风格

**参考设计**: https://dribbble.com/shots/26701777-RYMONTADA-Sports-Field-Booking-Tournament-App-UI-Design

**目标**: 将所有页面从 Duolingo 绿色风格改成 RYMONTADA 蓝色风格

---

## 📊 设计系统已更新

### 颜色系统
```
主蓝色:        #3C9EFF (Color(0xFF3C9EFF))
深蓝色:        #2E7FD6 (Color(0xFF2E7FD6))
浅蓝色:        #5CB3FF (Color(0xFF5CB3FF))
强调绿:        #4CAF50 (Color(0xFF4CAF50))   - 成功/确认
警告橙:        #FFA940 (Color(0xFFFFA940))
危险红:        #FF4D4F (Color(0xFFFF4D4F))

背景:          #F5F7FA (浅蓝灰)
卡片白:        #FFFFFF
文字深灰:      #1F2937
文字灰:        #6B7280
文字浅灰:      #9CA3AF
分割线:        #E5E7EB
```

### 圆角半径
- Small: 8px
- Medium: 12px (输入框、按钮)
- Large: 16px (卡片)
- XLarge: 20px

### 间距系统
- 8px, 12px, 16px, 20px, 24px

---

## 🎨 页面重写优先级

### Level 1: 认证流程 (最紧急)
- [ ] **SplashPage** - 启动页
  - 改: 绿色 → 蓝色渐变或纯蓝背景
  - 动画保持不变
  
- [ ] **LoginPage** - 登录页
  - 改: 按钮从绿色 → 蓝色
  - 输入框边框: 灰 → 浅蓝灰 (focus时变深蓝)
  - 文字颜色保持对比度
  
- [ ] **VerifyCodePage** - 验证码页
  - 改: 主色 绿→蓝，保持六位输入框样式
  - 倒计时文字: 绿→蓝
  
- [ ] **SetupProfilePage** - 资料设置
  - 改: 按钮、选中状态 绿→蓝
  - 水平线选择器: 保持圆角

---

### Level 2: 主页面结构 (高优先级)
- [ ] **MainPage** - 底部导航
  - 改: 导航栏背景 白色保持，选中颜色 绿→蓝
  - 图标保持风格
  
- [ ] **HomePage** - 首页/论坛页
  - 改: Feed 卡片阴影增加 (与蓝色搭配)
  - 分类筛选按钮: 绿→蓝 (selected), 灰 (unselected)
  - 点赞按钮: 绿→蓝
  
- [ ] **ProfilePage** - 个人中心
  - 改: 按钮颜色 绿→蓝
  - 背景、卡片保持白色

---

### Level 3: 论坛功能模块 (中优先级)
- [ ] **PostCreatePage** - 发帖页
  - 改: 提交按钮 绿→蓝
  - 图片上传区: 边框颜色 灰→蓝 (hover)
  
- [ ] **PostDetailPage** - 帖子详情
  - 改: 评论输入框下的按钮 绿→蓝
  - 点赞/踩按钮: 绿→蓝 (active)
  
- [ ] **CommentInputWidget** - 评论组件
  - 改: 回复/删除按钮 绿→蓝

---

### Level 4: 新功能页面 (低优先级，后续)
- [ ] **VenueListPage** - 球馆列表 (新建)
  - 主色: 蓝色
  - 卡片: 白色 + 蓝色阴影
  
- [ ] **ClubListPage** - 俱乐部列表 (新建)
  - 主色: 蓝色
  - 统计数字: 蓝色强调
  
- [ ] **ActivityLobbyPage** - 活动大厅 (新建)
  - 主色: 蓝色 (占坑), 绿色 (成局)

---

## 🔧 重写步骤

### 第 1 步: 更新主题 ✅ 已完成
- `lib/config/theme.dart` - 所有颜色和样式已改成蓝色

### 第 2 步: 检查使用点 (共 5 个主要地方)
```dart
// 1. 在 main.dart 中
theme: AppTheme.theme,

// 2. 所有颜色引用
AppTheme.primary              // #3C9EFF (蓝)
AppTheme.accent               // #4CAF50 (绿-成功用)
AppTheme.background           // #F5F7FA (背景)
AppTheme.surface              // #FFFFFF (卡片)

// 3. 按钮样式
ElevatedButton(
  onPressed: () {},
  child: Text('按钮'),  // 自动应用蓝色主题
)

// 4. 卡片样式
Card(
  child: ...,  // 自动应用蓝色阴影和圆角
)

// 5. 输入框样式
TextField(
  decoration: InputDecoration(...),  // 自动应用蓝色焦点
)
```

### 第 3 步: 逐页重写
每个页面只需要:
1. 打开页面文件
2. 检查是否有硬编码的 Color(0xFF58CC02) 绿色
3. 替换为 AppTheme.primary (蓝色) 或 AppTheme.accent (绿-仅限成功状态)
4. 检查 Icon, Text 颜色是否需要调整
5. 测试完后运行

---

## 📝 快速查询: 颜色使用规则

| 场景 | 旧颜色 | 新颜色 | 对应代码 |
|-----|-------|-------|---------|
| **主按钮** | 绿 #58CC02 | 蓝 #3C9EFF | `AppTheme.primary` |
| **按下效果** | 绿 #4CAF00 | 蓝 #2E7FD6 | `AppTheme.primaryDark` |
| **成功状态** | 绿 #58CC02 | 绿 #4CAF50 | `AppTheme.accent` |
| **文字主** | 灰 #3C3C3C | 灰 #1F2937 | `AppTheme.textPrimary` |
| **文字副** | 灰 #777777 | 灰 #6B7280 | `AppTheme.textSecondary` |
| **背景** | 灰 #F7F7F7 | 蓝灰 #F5F7FA | `AppTheme.background` |
| **卡片** | 白 #FFFFFF | 白 #FFFFFF | `AppTheme.surface` |
| **错误** | 红 #FF4B4B | 红 #FF4D4F | `AppTheme.danger` |
| **警告** | 黄 #FFC200 | 橙 #FFA940 | `AppTheme.warning` |

---

## 🚀 建议执行顺序

1. **今天**: Level 1 (认证流程) 3-4 小时
   - 这样用户体验最好，登录进来就是新风格
   
2. **明天**: Level 2 (主页面) 2-3 小时
   - HomePage 的卡片和按钮
   
3. **后天**: Level 3 (论坛功能) 2-3 小时
   - 发帖、评论相关
   
4. **周末**: Level 4 (球馆功能) - 待服务端需求确认

---

## 💡 技巧

### 快速搜索所有 Material 颜色引用
```
搜索: Color(0xFF58CC02)  (旧绿色)
替换为: AppTheme.primary

搜索: Color(0xFF4CAF00)  (旧深绿)
替换为: AppTheme.primaryDark

搜索: primary           (如果是直接引用 Colors/Theme)
检查是否需要改成 AppTheme.primary
```

### VS Code 快速替换命令
```
Ctrl+H 打开替换
Find: Color\(0xFF58CC02\)
Replace: AppTheme.primary
Replace All
```

### 测试快捷方式
修改一个页面后，直接 Hot Reload (Ctrl+S) 查看效果

---

## 📋 完成清单

- [ ] 主题系统更新 (theme.dart) ✅ 已完成
- [ ] SplashPage 改蓝色
- [ ] LoginPage 改蓝色
- [ ] VerifyCodePage 改蓝色
- [ ] SetupProfilePage 改蓝色
- [ ] MainPage 导航改蓝色
- [ ] HomePage 改蓝色
- [ ] ProfilePage 改蓝色
- [ ] PostCreatePage 改蓝色
- [ ] PostDetailPage 改蓝色
- [ ] CommentInputWidget 改蓝色
- [ ] 所有硬编码颜色改完
- [ ] 全面测试 (登录 → 发帖 → 评论 流程)

---

## 🎯 最终效果

完成后，整个 App 将呈现:
- 🔵 现代蓝色主色调 (而非绿色)
- 📱 精致的卡片设计 + 蓝色阴影
- ✨ 一致的圆角和间距 (8/12/16/20/24)
- 🎨 成功/警告/错误状态清晰可辨

---

**下一步**: 选择一个 Level 1 页面开始重写，告诉我你想先改哪个！
