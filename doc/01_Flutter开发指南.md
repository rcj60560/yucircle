# 01 - Flutter 开发指南

## 前言

本文档详细说明 Flutter 客户端的开发流程、需求清单和实现步骤。按照本文档的指引可以逐步完成 MVP 功能的开发。

---

## 目录

1. [项目初始化](#项目初始化)
2. [第一阶段：项目架构搭建](#第一阶段项目架构搭建-week-1)
3. [第二阶段：用户认证系统](#第二阶段用户认证系统-week-2)
4. [第三阶段：社区发帖功能](#第三阶段社区发帖功能-week-3-4)
5. [第四阶段：评论点赞功能](#第四阶段评论点赞功能-week-4-5)
6. [第五阶段：举报功能](#第五阶段举报功能-week-5)
7. [第六阶段：个人中心](#第六阶段个人中心-week-6)
8. [第七阶段：优化测试打包](#第七阶段优化测试打包-week-7)

---

## 项目初始化

### ✓ 已完成
- Flutter 项目创建
- 基础目录结构

### ⚙️ 需要配置
```bash
# 1. 清理缓存
flutter clean

# 2. 获取依赖
flutter pub get

# 3. 检查环境
flutter doctor -v

# 4. 创建项目文件夹结构
```

### 📁 项目文件结构（完整）

```
lib/
├── main.dart                 # 应用入口
├── config/
│   ├── app_config.dart      # 应用配置（API地址、常量等）
│   └── theme.dart           # 主题配置
├── models/                   # 数据模型
│   ├── user.dart
│   ├── post.dart
│   ├── comment.dart
│   └── ...
├── services/                 # API服务层
│   ├── api_client.dart      # HTTP客户端（Dio）
│   ├── auth_service.dart    # 认证服务
│   ├── post_service.dart    # 帖子服务
│   └── ...
├── providers/                # 状态管理（GetX）
│   ├── auth_controller.dart
│   ├── post_controller.dart
│   ├── user_controller.dart
│   └── ...
├── pages/                    # 页面
│   ├── auth/
│   │   ├── login_page.dart
│   │   └── verify_page.dart
│   ├── home/
│   │   ├── home_page.dart
│   │   └── feed_list.dart
│   ├── post/
│   │   ├── create_post_page.dart
│   │   └── post_detail_page.dart
│   ├── profile/
│   │   └── profile_page.dart
│   └── ...
├── widgets/                  # 可复用组件
│   ├── post_card.dart
│   ├── comment_item.dart
│   ├── user_avatar.dart
│   └── ...
└── utils/                    # 工具类
    ├── storage.dart         # 本地存储
    ├── constants.dart       # 常量
    └── helpers.dart         # 工具函数
```

---

## 第一阶段：项目架构搭建（Week 1）

### 目标
✅ 搭建项目骨架  
✅ 配置 GetX 状态管理  
✅ 配置 Dio 网络请求  
✅ 验证前后端通信

### 需求点清单

#### 1.1 依赖配置
**需要添加到 pubspec.yaml**

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  
  # 状态管理
  get: ^4.6.6
  
  # 网络请求
  dio: ^5.3.1
  
  # 本地存储
  shared_preferences: ^2.2.2
  
  # 图片处理
  image_picker: ^1.0.4
  cached_network_image: ^3.3.1
  
  # UI增强
  flutter_animate: ^4.1.1  # 简单动画
  intl: ^0.19.0           # 国际化（日期时间格式）

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

**执行命令**
```bash
flutter pub get
```

#### 1.2 GetX 状态管理初始化

**文件: lib/config/app_config.dart**

```dart
// API 配置
class AppConfig {
  // 后端服务器地址
  static const String apiBaseUrl = 'http://localhost:8080/api';
  
  // 环境配置
  static const bool isDebug = true;
}
```

**文件: lib/main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'config/app_config.dart';
import 'config/theme.dart';

void main() {
  runApp(const YuCircleApp());
}

class YuCircleApp extends StatelessWidget {
  const YuCircleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '羽圈',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const HomePage(),  // 暂时用首页
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('羽圈')),
      body: const Center(child: Text('Hello World')),
    );
  }
}
```

#### 1.3 Dio 网络请求配置

**文件: lib/services/api_client.dart**

```dart
import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import '../config/app_config.dart';

class ApiClient {
  late Dio _dio;
  
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
      ),
    );
    
    // 添加拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // TODO: 添加 JWT Token
          return handler.next(options);
        },
        onError: (error, handler) {
          // TODO: 处理错误
          return handler.next(error);
        },
      ),
    );
  }
  
  // GET 请求
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  // POST 请求
  Future<T> post<T>(
    String path, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  // 其他方法 (PUT, DELETE, etc.)
  // ...
}
```

#### 1.4 测试通信

**文件: lib/pages/test_page.dart**

```dart
import 'package:flutter/material.dart';
import '../services/api_client.dart';

class TestPage extends StatefulWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final apiClient = ApiClient();
  String? responseText;

  void testHealthCheck() async {
    try {
      final response = await apiClient.get('/health');
      setState(() {
        responseText = 'Success: $response';
      });
    } catch (e) {
      setState(() {
        responseText = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test API')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: testHealthCheck,
              child: const Text('Test Health Check'),
            ),
            const SizedBox(height: 20),
            Text(responseText ?? 'No response yet'),
          ],
        ),
      ),
    );
  }
}
```

### 验证清单
- [ ] 依赖安装成功（flutter pub get 无报错）
- [ ] 项目目录结构创建完毕
- [ ] 应用能正常启动
- [ ] ApiClient 能调用后端 /health 接口
- [ ] 接收到正确的 JSON 响应

---

## 第二阶段：用户认证系统（Week 2）

### 目标
✅ 实现手机号登录  
✅ 验证码发送/验证  
✅ Token 本地存储  
✅ 自动登录逻辑

### 需求点清单

#### 2.1 数据模型

**文件: lib/models/user.dart**

```dart
class User {
  final String id;
  final String phone;
  final String? nickname;
  final String? avatar;
  final String? bio;
  final String? badmintonLevel;  // 打球水平：入门/业余/准专业等
  final DateTime createdAt;

  User({
    required this.id,
    required this.phone,
    this.nickname,
    this.avatar,
    this.bio,
    this.badmintonLevel,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phone: json['phone'],
      nickname: json['nickname'],
      avatar: json['avatar'],
      bio: json['bio'],
      badmintonLevel: json['badmintonLevel'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'nickname': nickname,
      'avatar': avatar,
      'bio': bio,
      'badmintonLevel': badmintonLevel,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// API 响应模型
class LoginResponse {
  final String token;
  final User user;

  LoginResponse({
    required this.token,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      user: User.fromJson(json['user']),
    );
  }
}
```

#### 2.2 认证服务

**文件: lib/services/auth_service.dart**

```dart
import 'package:get/get.dart';
import '../models/user.dart';
import '../utils/storage.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient apiClient = ApiClient();
  final StorageManager storage = StorageManager();

  // 发送验证码
  Future<void> sendVerificationCode(String phone) async {
    try {
      await apiClient.post('/auth/send-code', data: {'phone': phone});
    } catch (e) {
      rethrow;
    }
  }

  // 登录（验证码）
  Future<LoginResponse> login(String phone, String code) async {
    try {
      final response = await apiClient.post(
        '/auth/login',
        data: {
          'phone': phone,
          'code': code,
        },
      );
      
      final loginResponse = LoginResponse.fromJson(response);
      
      // 保存 token 和用户信息
      await storage.saveToken(loginResponse.token);
      await storage.saveUser(loginResponse.user);
      
      return loginResponse;
    } catch (e) {
      rethrow;
    }
  }

  // 获取当前用户
  Future<User?> getCurrentUser() async {
    return storage.getUser();
  }

  // 检查登录状态
  Future<bool> isLoggedIn() async {
    final token = await storage.getToken();
    return token != null && token.isNotEmpty;
  }

  // 登出
  Future<void> logout() async {
    await storage.clearToken();
    await storage.clearUser();
  }
}
```

#### 2.3 本地存储工具

**文件: lib/utils/storage.dart**

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';

class StorageManager {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';

  // 保存 Token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // 获取 Token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // 删除 Token
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // 保存用户信息
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // 获取用户信息
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    return User.fromJson(jsonDecode(userJson));
  }

  // 删除用户信息
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // 清空所有
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
```

#### 2.4 认证控制器（GetX）

**文件: lib/providers/auth_controller.dart**

```dart
import 'package:get/get.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  final authService = AuthService();

  // 响应式变量
  var isLoggedIn = false.obs;
  var currentUser = Rx<User?>(null);
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  // 检查登录状态
  Future<void> checkLoginStatus() async {
    isLoggedIn.value = await authService.isLoggedIn();
    if (isLoggedIn.value) {
      currentUser.value = await authService.getCurrentUser();
    }
  }

  // 发送验证码
  Future<bool> sendCode(String phone) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await authService.sendVerificationCode(phone);
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 登录
  Future<bool> login(String phone, String code) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final response = await authService.login(phone, code);
      currentUser.value = response.user;
      isLoggedIn.value = true;
      
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 登出
  Future<void> logout() async {
    await authService.logout();
    isLoggedIn.value = false;
    currentUser.value = null;
  }
}
```

#### 2.5 登录页面

**文件: lib/pages/auth/login_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../providers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final authController = Get.put(AuthController());
  final phoneController = TextEditingController();
  final codeController = TextEditingController();
  bool codeSent = false;
  int countdownSeconds = 0;

  @override
  void dispose() {
    phoneController.dispose();
    codeController.dispose();
    super.dispose();
  }

  void sendCode() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty || phone.length != 11) {
      Get.snackbar('提示', '请输入正确的手机号');
      return;
    }

    final success = await authController.sendCode(phone);
    if (success) {
      setState(() {
        codeSent = true;
        countdownSeconds = 60;
      });
      Get.snackbar('成功', '验证码已发送');
      
      // 倒计时
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && countdownSeconds > 0) {
          setState(() => countdownSeconds--);
          sendCode();
        }
      });
    }
  }

  void login() async {
    final phone = phoneController.text.trim();
    final code = codeController.text.trim();

    if (phone.isEmpty || code.isEmpty) {
      Get.snackbar('提示', '请填写手机号和验证码');
      return;
    }

    final success = await authController.login(phone, code);
    if (success) {
      Get.snackbar('成功', '登录成功');
      // 跳转到主页
      Get.offAllNamed('/home');
    } else {
      Get.snackbar('错误', authController.errorMessage.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '请输入手机号',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '请输入验证码',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(() => ElevatedButton(
                  onPressed: authController.isLoading.value || countdownSeconds > 0 ? null : sendCode,
                  child: Text(countdownSeconds > 0 ? '${countdownSeconds}s' : '发送'),
                )),
              ],
            ),
            const SizedBox(height: 24),
            Obx(() => ElevatedButton(
              onPressed: authController.isLoading.value ? null : login,
              child: authController.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('登录'),
            )),
          ],
        ),
      ),
    );
  }
}
```

### 验证清单
- [ ] AuthService 完整实现
- [ ] 本地存储工具完成
- [ ] AuthController GetX 控制器完成
- [ ] 登录页面 UI 完成
- [ ] 验证码发送成功
- [ ] 登录成功并保存 Token
- [ ] 应用重启能自动登录

---

## 第三阶段：社区发帖功能（Week 3-4）

### 目标
✅ 首页 Feed 展示  
✅ 发帖功能（文字+图片）  
✅ 帖子详情页  
✅ 话题分类过滤

### 需求点清单

#### 3.1 数据模型

**文件: lib/models/post.dart**

```dart
class Post {
  final String id;
  final String userId;
  final String? userNickname;
  final String? userAvatar;
  final String? userLevel;       // 打球水平
  final String content;
  final List<String> images;     // 图片 URL 列表
  final String category;         // 话题类别
  final int likeCount;
  final int commentCount;
  final bool isLiked;            // 当前用户是否点过赞
  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    required this.id,
    required this.userId,
    this.userNickname,
    this.userAvatar,
    this.userLevel,
    required this.content,
    required this.images,
    required this.category,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['userId'],
      userNickname: json['userNickname'],
      userAvatar: json['userAvatar'],
      userLevel: json['userLevel'],
      content: json['content'],
      images: List<String>.from(json['images'] ?? []),
      category: json['category'],
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

// 创建帖子请求
class CreatePostRequest {
  final String content;
  final List<String> imageUrls;  // 上传后的图片 URL
  final String category;

  CreatePostRequest({
    required this.content,
    required this.imageUrls,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'images': imageUrls,
      'category': category,
    };
  }
}
```

#### 3.2 帖子服务

**文件: lib/services/post_service.dart**

```dart
import '../models/post.dart';
import 'api_client.dart';

class PostService {
  final ApiClient apiClient = ApiClient();

  // 获取帖子列表
  Future<List<Post>> getPostList({
    required int page,
    required int pageSize,
    String? category,
  }) async {
    try {
      final response = await apiClient.get(
        '/posts',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (category != null) 'category': category,
        },
      );
      
      final posts = (response['data'] as List)
          .map((p) => Post.fromJson(p))
          .toList();
      return posts;
    } catch (e) {
      rethrow;
    }
  }

  // 获取帖子详情
  Future<Post> getPostDetail(String postId) async {
    try {
      final response = await apiClient.get('/posts/$postId');
      return Post.fromJson(response['data']);
    } catch (e) {
      rethrow;
    }
  }

  // 创建帖子
  Future<Post> createPost(CreatePostRequest request) async {
    try {
      final response = await apiClient.post(
        '/posts',
        data: request.toJson(),
      );
      return Post.fromJson(response['data']);
    } catch (e) {
      rethrow;
    }
  }

  // 删除帖子
  Future<void> deletePost(String postId) async {
    try {
      await apiClient.post('/posts/$postId/delete');
    } catch (e) {
      rethrow;
    }
  }
}
```

#### 3.3 帖子控制器

**文件: lib/providers/post_controller.dart**

```dart
import 'package:get/get.dart';
import '../models/post.dart';
import '../services/post_service.dart';

class PostController extends GetxController {
  final postService = PostService();

  var posts = <Post>[].obs;
  var isLoading = false.obs;
  var selectedCategory = 'all'.obs;
  var currentPage = 1;

  final List<String> categories = [
    'all',
    '运动保健',
    '技术交流',
    '器材分享',
    '比赛讨论',
    '约球',
  ];

  @override
  void onInit() {
    super.onInit();
    loadPosts();
  }

  // 加载帖子
  Future<void> loadPosts() async {
    try {
      isLoading.value = true;
      currentPage = 1;
      
      final newPosts = await postService.getPostList(
        page: currentPage,
        pageSize: 20,
        category: selectedCategory.value == 'all' ? null : selectedCategory.value,
      );
      
      posts.value = newPosts;
    } catch (e) {
      Get.snackbar('错误', '加载帖子失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 加载更多（分页）
  Future<void> loadMore() async {
    try {
      currentPage++;
      
      final morePosts = await postService.getPostList(
        page: currentPage,
        pageSize: 20,
        category: selectedCategory.value == 'all' ? null : selectedCategory.value,
      );
      
      posts.addAll(morePosts);
    } catch (e) {
      Get.snackbar('错误', '加载更多失败: $e');
      currentPage--;
    }
  }

  // 切换分类
  Future<void> switchCategory(String category) async {
    selectedCategory.value = category;
    await loadPosts();
  }

  // 创建帖子
  Future<bool> createPost(String content, List<String> imageUrls, String category) async {
    try {
      isLoading.value = true;
      
      final request = CreatePostRequest(
        content: content,
        imageUrls: imageUrls,
        category: category,
      );
      
      final newPost = await postService.createPost(request);
      posts.insert(0, newPost);  // 新帖子插到最前面
      
      return true;
    } catch (e) {
      Get.snackbar('错误', '创建帖子失败: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
```

#### 3.4 首页 Feed 页面

**文件: lib/pages/home/home_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../providers/post_controller.dart';
import '../../widgets/post_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PostController>(
      init: PostController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('羽圈'),
            elevation: 0,
          ),
          body: Column(
            children: [
              // 话题分类 tabs
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.categories.length,
                  itemBuilder: (context, index) {
                    final category = controller.categories[index];
                    final isSelected = controller.selectedCategory.value == category;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: GestureDetector(
                        onTap: () => controller.switchCategory(category),
                        child: Chip(
                          label: Text(category),
                          selected: isSelected,
                          backgroundColor: isSelected
                              ? Colors.green
                              : Colors.grey[200],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 帖子列表
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value && controller.posts.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (controller.posts.isEmpty) {
                    return const Center(child: Text('暂无帖子'));
                  }
                  
                  return ListView.builder(
                    itemCount: controller.posts.length + 1,
                    itemBuilder: (context, index) {
                      if (index == controller.posts.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            onPressed: () => controller.loadMore(),
                            child: const Text('加载更多'),
                          ),
                        );
                      }
                      
                      final post = controller.posts[index];
                      return PostCard(post: post);
                    },
                  );
                }),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Get.toNamed('/create-post'),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
```

#### 3.5 发帖页面

**文件: lib/pages/post/create_post_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/post_controller.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final contentController = TextEditingController();
  final List<XFile> selectedImages = [];
  String selectedCategory = '技术交流';
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }

  void pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        selectedImages.addAll(images);
      });
    }
  }

  void removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  void publish() async {
    final content = contentController.text.trim();
    if (content.isEmpty) {
      Get.snackbar('提示', '请输入内容');
      return;
    }

    // TODO: 上传图片获取 URLs
    List<String> imageUrls = [];

    final postController = Get.find<PostController>();
    final success = await postController.createPost(
      content,
      imageUrls,
      selectedCategory,
    );

    if (success) {
      Get.snackbar('成功', '发帖成功');
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发帖'),
        actions: [
          TextButton(
            onPressed: publish,
            child: const Text('发布'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 话题选择
              const Text('选择话题'),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                items: [
                  '运动保健',
                  '技术交流',
                  '器材分享',
                  '比赛讨论',
                  '约球',
                ].map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              
              // 内容输入
              const Text('内容'),
              const SizedBox(height: 8),
              TextField(
                controller: contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '说说你的羽毛球心得...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // 图片选择
              const Text('添加图片（最多9张）'),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  spacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: selectedImages.length + 1,
                itemBuilder: (context, index) {
                  if (index == selectedImages.length) {
                    return GestureDetector(
                      onTap: selectedImages.length < 9 ? pickImages : null,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add),
                      ),
                    );
                  }
                  
                  return Stack(
                    children: [
                      Image.file(
                        // TODO: convert XFile to File
                        // File(selectedImages[index].path),
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => removeImage(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 验证清单
- [ ] 帖子模型完成
- [ ] PostService 完整实现
- [ ] PostController 完成
- [ ] 首页 Feed 能正常展示帖子列表
- [ ] 话题分类过滤功能正常
- [ ] 分页加载更多功能正常
- [ ] 发帖页面 UI 完成
- [ ] 发帖成功并显示在 Feed 顶部

---

## 第四阶段：评论点赞功能（Week 4-5）

### 目标
✅ 二级评论系统  
✅ 点赞功能  
✅ 帖子详情页  
✅ 评论互动

### 需求点清单

#### 4.1 数据模型

**文件: lib/models/comment.dart**

```dart
class Comment {
  final String id;
  final String postId;
  final String userId;
  final String? userNickname;
  final String? userAvatar;
  final String content;
  final String? parentCommentId;  // 如果不为空，表示这是一条回复
  final String? replyToUserId;    // 回复给谁
  final String? replyToUserNickname;
  final int likeCount;
  final bool isLiked;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    this.userNickname,
    this.userAvatar,
    required this.content,
    this.parentCommentId,
    this.replyToUserId,
    this.replyToUserNickname,
    required this.likeCount,
    required this.isLiked,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['postId'],
      userId: json['userId'],
      userNickname: json['userNickname'],
      userAvatar: json['userAvatar'],
      content: json['content'],
      parentCommentId: json['parentCommentId'],
      replyToUserId: json['replyToUserId'],
      replyToUserNickname: json['replyToUserNickname'],
      likeCount: json['likeCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
```

#### 4.2 评论服务

**文件: lib/services/comment_service.dart**

```dart
import '../models/comment.dart';
import 'api_client.dart';

class CommentService {
  final ApiClient apiClient = ApiClient();

  // 获取评论列表
  Future<List<Comment>> getComments({
    required String postId,
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await apiClient.get(
        '/posts/$postId/comments',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      
      final comments = (response['data'] as List)
          .map((c) => Comment.fromJson(c))
          .toList();
      return comments;
    } catch (e) {
      rethrow;
    }
  }

  // 创建评论（一级）
  Future<Comment> createComment({
    required String postId,
    required String content,
  }) async {
    try {
      final response = await apiClient.post(
        '/posts/$postId/comments',
        data: {
          'content': content,
        },
      );
      return Comment.fromJson(response['data']);
    } catch (e) {
      rethrow;
    }
  }

  // 回复评论（二级）
  Future<Comment> replyComment({
    required String postId,
    required String parentCommentId,
    required String replyToUserId,
    required String content,
  }) async {
    try {
      final response = await apiClient.post(
        '/posts/$postId/comments/$parentCommentId/reply',
        data: {
          'content': content,
          'replyToUserId': replyToUserId,
        },
      );
      return Comment.fromJson(response['data']);
    } catch (e) {
      rethrow;
    }
  }

  // 点赞评论
  Future<void> likeComment(String commentId) async {
    try {
      await apiClient.post('/comments/$commentId/like');
    } catch (e) {
      rethrow;
    }
  }

  // 取消点赞评论
  Future<void> unlikeComment(String commentId) async {
    try {
      await apiClient.post('/comments/$commentId/unlike');
    } catch (e) {
      rethrow;
    }
  }

  // 删除评论
  Future<void> deleteComment(String commentId) async {
    try {
      await apiClient.post('/comments/$commentId/delete');
    } catch (e) {
      rethrow;
    }
  }
}
```

#### 4.3 点赞服务

**文件: lib/services/like_service.dart**

```dart
import 'api_client.dart';

class LikeService {
  final ApiClient apiClient = ApiClient();

  // 点赞帖子
  Future<void> likePost(String postId) async {
    try {
      await apiClient.post('/posts/$postId/like');
    } catch (e) {
      rethrow;
    }
  }

  // 取消点赞帖子
  Future<void> unlikePost(String postId) async {
    try {
      await apiClient.post('/posts/$postId/unlike');
    } catch (e) {
      rethrow;
    }
  }
}
```

#### 4.4 帖子详情页

**文件: lib/pages/post/post_detail_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/post.dart';
import '../../models/comment.dart';
import '../../services/comment_service.dart';
import '../../services/like_service.dart';

class PostDetailPage extends StatefulWidget {
  final Post post;

  const PostDetailPage({Key? key, required this.post}) : super(key: key);

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final commentService = CommentService();
  final likeService = LikeService();
  final commentController = TextEditingController();
  
  late Post currentPost;
  List<Comment> comments = [];
  bool isLoadingComments = false;
  String? replyingToCommentId;
  String? replyingToUserId;
  String? replyingToUserNickname;

  @override
  void initState() {
    super.initState();
    currentPost = widget.post;
    loadComments();
  }

  Future<void> loadComments() async {
    setState(() => isLoadingComments = true);
    try {
      final newComments = await commentService.getComments(
        postId: currentPost.id,
        page: 1,
        pageSize: 50,
      );
      setState(() => comments = newComments);
    } catch (e) {
      Get.snackbar('错误', '加载评论失败: $e');
    } finally {
      setState(() => isLoadingComments = false);
    }
  }

  Future<void> toggleLike() async {
    try {
      if (currentPost.isLiked) {
        await likeService.unlikePost(currentPost.id);
      } else {
        await likeService.likePost(currentPost.id);
      }
      
      setState(() {
        currentPost = Post(
          id: currentPost.id,
          userId: currentPost.userId,
          userNickname: currentPost.userNickname,
          userAvatar: currentPost.userAvatar,
          userLevel: currentPost.userLevel,
          content: currentPost.content,
          images: currentPost.images,
          category: currentPost.category,
          likeCount: currentPost.isLiked
              ? currentPost.likeCount - 1
              : currentPost.likeCount + 1,
          commentCount: currentPost.commentCount,
          isLiked: !currentPost.isLiked,
          createdAt: currentPost.createdAt,
          updatedAt: currentPost.updatedAt,
        );
      });
    } catch (e) {
      Get.snackbar('错误', '操作失败: $e');
    }
  }

  Future<void> submitComment() async {
    final content = commentController.text.trim();
    if (content.isEmpty) {
      Get.snackbar('提示', '请输入评论内容');
      return;
    }

    try {
      Comment newComment;
      
      if (replyingToCommentId != null) {
        // 二级回复
        newComment = await commentService.replyComment(
          postId: currentPost.id,
          parentCommentId: replyingToCommentId!,
          replyToUserId: replyingToUserId!,
          content: content,
        );
      } else {
        // 一级评论
        newComment = await commentService.createComment(
          postId: currentPost.id,
          content: content,
        );
      }

      setState(() {
        comments.insert(0, newComment);
        commentController.clear();
        replyingToCommentId = null;
        replyingToUserId = null;
        replyingToUserNickname = null;
      });
      
      Get.snackbar('成功', '评论成功');
    } catch (e) {
      Get.snackbar('错误', '评论失败: $e');
    }
  }

  void startReply(Comment comment) {
    setState(() {
      replyingToCommentId = comment.id;
      replyingToUserId = comment.userId;
      replyingToUserNickname = comment.userNickname;
    });
    
    FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('帖子详情')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // 帖子内容
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 用户信息
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(
                              currentPost.userAvatar ?? '',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(currentPost.userNickname ?? '未知用户'),
                              Text(
                                currentPost.userLevel ?? '',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // 话题标签
                      Chip(label: Text(currentPost.category)),
                      const SizedBox(height: 12),
                      
                      // 内容
                      Text(currentPost.content),
                      const SizedBox(height: 12),
                      
                      // 图片
                      if (currentPost.images.isNotEmpty)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            spacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: currentPost.images.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              currentPost.images[index],
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      
                      const SizedBox(height: 12),
                      
                      // 交互数据
                      Row(
                        children: [
                          Icon(
                            currentPost.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: currentPost.isLiked ? Colors.red : null,
                          ),
                          const SizedBox(width: 4),
                          Text('${currentPost.likeCount}'),
                          const SizedBox(width: 16),
                          const Icon(Icons.comment),
                          const SizedBox(width: 4),
                          Text('${currentPost.commentCount}'),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const Divider(),
                
                // 评论列表
                if (isLoadingComments)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  )
                else if (comments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('暂无评论'),
                  )
                else
                  ...comments.map((comment) {
                    return _buildCommentItem(comment);
                  }).toList(),
              ],
            ),
          ),
          
          // 评论输入框
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (replyingToCommentId != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('回复 @$replyingToUserNickname'),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              replyingToCommentId = null;
                              replyingToUserId = null;
                              replyingToUserNickname = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: replyingToCommentId != null
                              ? '输入回复'
                              : '写评论...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: submitComment,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 一级评论
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(comment.userAvatar ?? ''),
                radius: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment.userNickname ?? '未知用户'),
                    Text(comment.content),
                    Row(
                      children: [
                        Icon(
                          comment.isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                          color: comment.isLiked ? Colors.red : null,
                        ),
                        const SizedBox(width: 4),
                        Text('${comment.likeCount}'),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => startReply(comment),
                          child: const Text(
                            '回复',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 二级回复会显示在下方（简化版）
        ],
      ),
    );
  }
}
```

### 验证清单
- [ ] Comment 模型完成
- [ ] CommentService 完整实现
- [ ] LikeService 完成
- [ ] 帖子详情页能正常显示
- [ ] 评论列表能正常加载
- [ ] 能够评论和回复
- [ ] 点赞功能正常工作
- [ ] 点赞数实时更新

---

## 第五阶段：举报功能（Week 5）

### 目标
✅ 举报帖子/评论/用户  
✅ 举报原因选择  
✅ 举报历史记录

### 需求点清单

#### 5.1 数据模型

**文件: lib/models/report.dart**

```dart
class Report {
  final String id;
  final String reporterId;
  final String? reportedPostId;
  final String? reportedCommentId;
  final String? reportedUserId;
  final String reason;  // 举报原因
  final String? description;
  final String status;  // pending / reviewed / resolved
  final DateTime createdAt;

  Report({
    required this.id,
    required this.reporterId,
    this.reportedPostId,
    this.reportedCommentId,
    this.reportedUserId,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      reporterId: json['reporterId'],
      reportedPostId: json['reportedPostId'],
      reportedCommentId: json['reportedCommentId'],
      reportedUserId: json['reportedUserId'],
      reason: json['reason'],
      description: json['description'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
```

#### 5.2 举报服务

**文件: lib/services/report_service.dart**

```dart
import '../models/report.dart';
import 'api_client.dart';

class ReportService {
  final ApiClient apiClient = ApiClient();

  static const List<String> reportReasons = [
    '广告垃圾',
    '人身攻击',
    '骚扰、骂人',
    '色情、低俗',
    '违反法律法规',
    '其他',
  ];

  // 举报帖子
  Future<void> reportPost({
    required String postId,
    required String reason,
    String? description,
  }) async {
    try {
      await apiClient.post(
        '/reports',
        data: {
          'reportedPostId': postId,
          'reason': reason,
          'description': description,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // 举报评论
  Future<void> reportComment({
    required String commentId,
    required String reason,
    String? description,
  }) async {
    try {
      await apiClient.post(
        '/reports',
        data: {
          'reportedCommentId': commentId,
          'reason': reason,
          'description': description,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // 举报用户
  Future<void> reportUser({
    required String userId,
    required String reason,
    String? description,
  }) async {
    try {
      await apiClient.post(
        '/reports',
        data: {
          'reportedUserId': userId,
          'reason': reason,
          'description': description,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // 获取我的举报历史
  Future<List<Report>> getMyReports() async {
    try {
      final response = await apiClient.get('/reports/my');
      final reports = (response['data'] as List)
          .map((r) => Report.fromJson(r))
          .toList();
      return reports;
    } catch (e) {
      rethrow;
    }
  }
}
```

#### 5.3 举报对话框

**文件: lib/widgets/report_dialog.dart**

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/report_service.dart';

class ReportDialog extends StatefulWidget {
  final String? postId;
  final String? commentId;
  final String? userId;
  final String title;

  const ReportDialog({
    Key? key,
    this.postId,
    this.commentId,
    this.userId,
    required this.title,
  }) : super(key: key);

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final reportService = ReportService();
  String? selectedReason;
  final descriptionController = TextEditingController();
  bool isSubmitting = false;

  Future<void> submitReport() async {
    if (selectedReason == null) {
      Get.snackbar('提示', '请选择举报原因');
      return;
    }

    setState(() => isSubmitting = true);

    try {
      if (widget.postId != null) {
        await reportService.reportPost(
          postId: widget.postId!,
          reason: selectedReason!,
          description: descriptionController.text.isEmpty
              ? null
              : descriptionController.text,
        );
      } else if (widget.commentId != null) {
        await reportService.reportComment(
          commentId: widget.commentId!,
          reason: selectedReason!,
          description: descriptionController.text.isEmpty
              ? null
              : descriptionController.text,
        );
      } else if (widget.userId != null) {
        await reportService.reportUser(
          userId: widget.userId!,
          reason: selectedReason!,
          description: descriptionController.text.isEmpty
              ? null
              : descriptionController.text,
        );
      }

      Get.back();
      Get.snackbar('成功', '举报已提交，感谢您的反馈');
    } catch (e) {
      Get.snackbar('错误', '举报失败: $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('举报原因 *'),
            const SizedBox(height: 8),
            ...ReportService.reportReasons.map((reason) {
              return RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: selectedReason,
                onChanged: (value) {
                  setState(() => selectedReason = value);
                },
              );
            }).toList(),
            const SizedBox(height: 16),
            const Text('详细描述（可选）'),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '请详细描述问题...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : submitReport,
          child: isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('举报'),
        ),
      ],
    );
  }
}
```

### 验证清单
- [ ] Report 模型完成
- [ ] ReportService 完整实现
- [ ] 举报对话框能正常弹出
- [ ] 能够举报帖子/评论/用户
- [ ] 举报成功有反馈

---

## 第六阶段：个人中心（Week 6）

### 目标
✅ 个人资料展示  
✅ 资料编辑  
✅ 我的发帖列表  
✅ 我的点赞列表

### 需求点清单

#### 6.1 用户信息编辑

**文件: lib/pages/profile/profile_page.dart**

```dart
// 详见文档末尾的完整实现
```

### 验证清单
- [ ] 个人中心页面完成
- [ ] 资料编辑功能完成
- [ ] 我的发帖列表完成
- [ ] 我的点赞列表完成
- [ ] 头像上传功能完成
- [ ] 设置/退出登录完成

---

## 第七阶段：优化测试打包（Week 7）

### 目标
✅ 性能优化  
✅ Bug 修复  
✅ 充分测试  
✅ 打包发布

### 需要做的事

#### 7.1 性能优化
- [ ] 列表虚拟滚动
- [ ] 图片懒加载和缓存
- [ ] API 缓存机制
- [ ] 减少不必要重建

#### 7.2 测试
- [ ] 单元测试
- [ ] 集成测试
- [ ] 真机测试（iOS/Android）
- [ ] 边界情况测试

#### 7.3 打包配置
- [ ] Android 签名配置
- [ ] iOS 证书配置
- [ ] 版本号和 Build 号设置
- [ ] App 图标和启动屏

#### 7.4 发布前检查
- [ ] 隐私政策
- [ ] 用户协议
- [ ] 版本号递增
- [ ] 发布说明

---

## 常用命令速查表

```bash
# 项目管理
flutter clean              # 清理缓存
flutter pub get           # 获取依赖
flutter pub upgrade       # 更新依赖
flutter doctor            # 检查环境

# 开发运行
flutter run               # 调试运行
flutter run -v            # 详细日志运行

# 构建
flutter build apk         # 构建 APK
flutter build ios         # 构建 iOS

# 代码质量
flutter analyze           # 代码分析
dartfmt -w lib/          # 格式化代码
```

---

## 常见问题排查

### Q: 依赖冲突错误
```
A: 运行 flutter pub get --enforce-lockfile
   或删除 pubspec.lock 重新 flutter pub get
```

### Q: Hot Reload 失效
```
A: 运行 flutter run 的时候按 R 完整热启动
   或重新 flutter run
```

### Q: 网络请求失败
```
A: 检查后端服务是否启动
   检查 ApiConfig 中的 baseUrl 是否正确
   检查网络连接
```

---

## 下一步

完成本阶段后，查看 [02_后端API设计.md](02_后端API设计.md) 了解后端实现要求。
