import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../utils/storage.dart';

/// API 客户端 - 支持 Mock 模式和真实后端
class ApiClient {
  static late final Dio _dio;

  static Future<Options> _authOptions() async {
    final token = await StorageManager.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  static void init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
      validateStatus: (status) => true,  // ← 接受所有状态码，不抛异常
    ));
  }

  // ── 认证相关 ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> sendSmsCode(String phone) async {
    if (AppConfig.mockMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      return {'code': 0, 'msg': 'ok'};
    }
    try {
      final response = await _dio.post(
        '/auth/send-code',
        data: {'phone': phone},
      );
      return response.data ?? {'code': 500, 'msg': 'unknown error'};
    } catch (e) {
      print('sendSmsCode error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> verifySmsCode(
      String phone, String code) async {
    if (AppConfig.mockMode) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (code == AppConfig.mockSmsCode) {
        return {
          'code': 200,  // ← 改为 200
          'msg': '登录成功',
          'data': {
            'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
            'user': {
              'id': 'user_001',
              'phone': phone,
              'nickname': '',
              'badmintonLevel': '',
            },
          }
        };
      }
      return {'code': 400, 'msg': '验证码错误'};  // ← 改为 400
    }
    try {
      final response = await _dio.post(
        '/auth/verify-code',
        data: {'phone': phone, 'code': code},
      );
      return response.data ?? {'code': 500, 'msg': 'unknown error'};
    } catch (e) {
      print('verifySmsCode error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> setupProfile({
    required String nickname,
    required String level,
    required String phone,
  }) async {
    if (AppConfig.mockMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'code': 200,  // ← 改为 200
        'msg': '资料更新成功',
        'data': {
          'id': 'user_001',
          'nickname': nickname,
          'badmintonLevel': level,
          'phone': phone,
          'avatar': '',
        }
      };
    }
    try {
      final token = await StorageManager.getToken();
      final response = await _dio.put(
        '/auth/profile',
        data: {
          'nickname': nickname,
          'badmintonLevel': level,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response.data ?? {'code': 500, 'msg': 'unknown error'};
    } catch (e) {
      print('setupProfile error: $e');
      rethrow;
    }
  }

  // ── 帖子相关 ──────────────────────────────────────────────
  
  /// 发布帖子
  static Future<Map<String, dynamic>> createPost({
    required String title,
    required String content,
    String category = '技术交流',
    String images = '',
  }) async {
    if (AppConfig.mockMode) {
      await Future.delayed(const Duration(milliseconds: 600));
      return {
        'code': 200,
        'msg': '发帖成功',
        'data': {
          'id': DateTime.now().millisecondsSinceEpoch,
          'title': title,
          'content': content,
          'category': category,
          'likeCount': 0,
          'commentCount': 0,
          'createdAt': DateTime.now().toIso8601String(),
        }
      };
    }
    try {
      final token = await StorageManager.getToken();
      final response = await _dio.post(
        '/posts',
        data: {
          'title': title,
          'content': content,
          'category': category,
          'images': images,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      // 检查 HTTP 状态码
      if (response.statusCode == 200 || response.statusCode == null) {
        return response.data ?? {'code': 500, 'msg': 'no response data'};
      } else {
        return {
          'code': response.statusCode ?? 500,
          'msg': 'HTTP Error: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('createPost error: $e');
      return {'code': 500, 'msg': 'Network error: $e'};
    }
  }

  /// 获取帖子列表
  static Future<Map<String, dynamic>> getPostList({
    int page = 1,
    int limit = 10,
  }) async {
    if (AppConfig.mockMode) {
      await Future.delayed(const Duration(milliseconds: 600));
      return {
        'code': 200,
        'msg': 'success',
        'data': {
          'total': 30,
          'page': page,
          'limit': limit,
          'records': List.generate(
            10,
            (i) => {
              'id': i + 1,
              'userId': (i % 3) + 1,
              'nickname': '球友${i + 1}号',
              'avatar': '',
              'category': _MockConstants.mockCategories[i % _MockConstants.mockCategories.length],
              'title': _MockConstants.mockTitles[i % _MockConstants.mockTitles.length],
              'content': _MockConstants.mockContents[i % _MockConstants.mockContents.length],
              'likeCount': (i + 1) * 3,
              'commentCount': i * 2,
              'createdAt': DateTime.now().subtract(Duration(hours: i + 1)).toIso8601String(),
            },
          ),
        }
      };
    }
    try {
      final response = await _dio.get(
        '/posts',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      
      // 检查 HTTP 状态码
      if (response.statusCode == 200 || response.statusCode == null) {
        return response.data ?? {'code': 500, 'msg': 'no response data'};
      } else {
        return {
          'code': response.statusCode ?? 500,
          'msg': 'HTTP Error: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('getPostList error: $e');
      return {'code': 500, 'msg': 'Network error: $e'};
    }
  }

  /// 获取帖子详情
  static Future<Map<String, dynamic>> getPost(int id) async {
    if (AppConfig.mockMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      return {
        'code': 200,
        'msg': 'success',
        'data': {
          'id': id,
          'userId': 1,
          'nickname': '球友A',
          'avatar': '',
          'category': '技术交流',
          'title': '后场高球技巧分享',
          'content': '后场高球一直不到位？教你几个小技巧...',
          'likeCount': 10,
          'commentCount': 5,
          'viewCount': 100,
          'createdAt': DateTime.now().toIso8601String(),
        }
      };
    }
    try {
      final response = await _dio.get('/posts/$id');
      return response.data ?? {'code': 500, 'msg': 'unknown error'};
    } catch (e) {
      print('getPost error: $e');
      rethrow;
    }
  }

  // ── 评论相关 ──────────────────────────────────────────────

  /// 发表评论
  static Future<Map<String, dynamic>> createComment({
    required int postId,
    required String content,
    int? parentId,
    int? rootId,
  }) async {
    try {
      final token = await StorageManager.getToken();
      final response = await _dio.post(
        '/comments',
        data: {
          'postId': postId,
          'content': content,
          'parentId': parentId,
          'rootId': rootId,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      if (response.statusCode == 200 || response.statusCode == null) {
        return response.data ?? {'code': 500, 'msg': 'no response data'};
      } else {
        return {
          'code': response.statusCode ?? 500,
          'msg': 'HTTP Error: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('createComment error: $e');
      return {'code': 500, 'msg': 'Network error: $e'};
    }
  }

  /// 获取帖子的评论列表
  static Future<Map<String, dynamic>> getComments(int postId) async {
    try {
      final response = await _dio.get('/comments/post/$postId');
      
      if (response.statusCode == 200 || response.statusCode == null) {
        return response.data ?? {'code': 500, 'msg': 'no response data'};
      } else {
        return {
          'code': response.statusCode ?? 500,
          'msg': 'HTTP Error: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('getComments error: $e');
      return {'code': 500, 'msg': 'Network error: $e'};
    }
  }

  /// 删除评论
  static Future<Map<String, dynamic>> deleteComment(int commentId) async {
    try {
      final token = await StorageManager.getToken();
      final response = await _dio.delete(
        '/comments/$commentId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      if (response.statusCode == 200 || response.statusCode == null) {
        return response.data ?? {'code': 500, 'msg': 'no response data'};
      } else {
        return {
          'code': response.statusCode ?? 500,
          'msg': 'HTTP Error: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('deleteComment error: $e');
      return {'code': 500, 'msg': 'Network error: $e'};
    }
  }

  // ── 点赞相关 ──────────────────────────────────────────────

  /// 切换点赞（post/comment）
  /// type: "like" 或 "dislike"
  static Future<Map<String, dynamic>> toggleLike({
    required String objectType,  // "post" 或 "comment"
    required int objectId,
    required String type,  // "like" 或 "dislike"
  }) async {
    try {
      final token = await StorageManager.getToken();
      final response = await _dio.post(
        '/likes',
        data: {
          'objectType': objectType,
          'objectId': objectId,
          'type': type,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      if (response.statusCode == 200 || response.statusCode == null) {
        return response.data ?? {'code': 500, 'msg': 'no response data'};
      } else {
        return {
          'code': response.statusCode ?? 500,
          'msg': 'HTTP Error: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('toggleLike error: $e');
      return {'code': 500, 'msg': 'Network error: $e'};
    }
  }

  /// 获取点赞统计
  static Future<Map<String, dynamic>> getLikeStats({
    required String objectType,  // "post" 或 "comment"
    required int objectId,
  }) async {
    try {
      final response = await _dio.get(
        '/likes/stats/$objectType/$objectId',
      );
      
      if (response.statusCode == 200 || response.statusCode == null) {
        return response.data ?? {'code': 500, 'msg': 'no response data'};
      } else {
        return {
          'code': response.statusCode ?? 500,
          'msg': 'HTTP Error: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('getLikeStats error: $e');
      return {'code': 500, 'msg': 'Network error: $e'};
    }
  }

  /// 更新帖子
  static Future<Map<String, dynamic>> updatePost({
    required int id,
    required String title,
    required String content,
    String category = '技术交流',
  }) async {
    if (AppConfig.mockMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'code': 200,
        'msg': '更新成功',
        'data': {'id': id, 'title': title, 'content': content}
      };
    }
    try {
      final token = await StorageManager.getToken();
      final response = await _dio.put(
        '/posts/$id',
        data: {'title': title, 'content': content, 'category': category},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response.data ?? {'code': 500, 'msg': 'unknown error'};
    } catch (e) {
      print('updatePost error: $e');
      rethrow;
    }
  }

  /// 删除帖子
  static Future<Map<String, dynamic>> deletePost(int id) async {
    if (AppConfig.mockMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      return {'code': 200, 'msg': '删除成功'};
    }
    try {
      final token = await StorageManager.getToken();
      final response = await _dio.delete(
        '/posts/$id',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response.data ?? {'code': 500, 'msg': 'unknown error'};
    } catch (e) {
      print('deletePost error: $e');
      rethrow;
    }
  }

  // ── 场馆和俱乐部相关 ──────────────────────────────────────────────
  
  /// 获取所有场馆列表
  static Future<Map<String, dynamic>> getVenues() async {
    if (AppConfig.mockMode) {
      await Future.delayed(const Duration(milliseconds: 600));
      return {
        'code': 200,
        'msg': 'ok',
        'data': [
          {
            'id': 1,
            'name': '晴天羽毛球馆',
            'address': '成都市武侯区一环路南三段1号',
            'city': '成都',
            'courtCount': 10,
            'latitude': 30.5528,
            'longitude': 104.0666,
            'distance': 3.2,
            'onlineCount': 23,
            'broadcastMessage': '1号场高质量缺人，L4 以上速来',
          }
        ]
      };
    }
    try {
      final response = await _dio.get('/venues');
      return response.data ?? {'code': 500, 'msg': 'unknown error'};
    } catch (e) {
      print('getVenues error: $e');
      return {'code': 500, 'msg': '获取场馆列表失败: $e'};
    }
  }

  /// 获取指定场馆的俱乐部列表
  static Future<Map<String, dynamic>> getClubsByVenue(int venueId) async {
    if (AppConfig.mockMode) {
      await Future.delayed(const Duration(milliseconds: 600));
      return {
        'code': 200,
        'msg': 'ok',
        'data': [
          {
            'id': 1,
            'venueId': venueId,
            'name': '俱乐部 A',
            'description': '羽毛球爱好者聚集地',
            'creatorId': 1,
            'status': 'active',
            'broadcastCredits': 5,
            'createdAt': '2026-05-01T10:00:00',
            'todayActivityCount': 2,
            'onlineCount': 8,
            'hasActiveBoradcast': true,
          },
          {
            'id': 2,
            'venueId': venueId,
            'name': '俱乐部 B',
            'description': '高手对决的地方',
            'creatorId': 2,
            'status': 'active',
            'broadcastCredits': 3,
            'createdAt': '2026-05-02T10:00:00',
            'todayActivityCount': 1,
            'onlineCount': 5,
            'hasActiveBoradcast': false,
          },
          {
            'id': 3,
            'venueId': venueId,
            'name': '俱乐部 C',
            'description': '新手友好型俱乐部',
            'creatorId': 3,
            'status': 'active',
            'broadcastCredits': 2,
            'createdAt': '2026-05-03T10:00:00',
            'todayActivityCount': 3,
            'onlineCount': 12,
            'hasActiveBoradcast': true,
          },
        ]
      };
    }
    try {
      final response = await _dio.get('/clubs/venue/$venueId');
      return response.data ?? {'code': 500, 'msg': 'unknown error'};
    } catch (e) {
      print('getClubsByVenue error: $e');
      return {'code': 500, 'msg': '获取俱乐部列表失败: $e'};
    }
  }

  /// 获取俱乐部活动列表（用于进入大厅）
  static Future<Map<String, dynamic>> getClubActivities(int clubId) async {
    try {
      final response = await _dio.get('/clubs/$clubId/activities');
      return response.data ?? {'code': 500, 'msg': 'unknown error'};
    } catch (e) {
      print('getClubActivities error: $e');
      return {'code': 500, 'msg': '获取俱乐部活动失败: $e'};
    }
  }

  /// 进入活动大厅
  static Future<Map<String, dynamic>> enterActivityLobby(int activityId) async {
    try {
      final response = await _dio.post(
        '/activities/$activityId/enter',
        options: await _authOptions(),
      );
      return response.data ?? {'code': 500, 'msg': 'unknown error'};
    } catch (e) {
      print('enterActivityLobby error: $e');
      return {'code': 500, 'msg': '进入大厅失败: $e'};
    }
  }

  /// 获取活动大厅快照
  static Future<Map<String, dynamic>> getActivityLobbySnapshot(int activityId) async {
    try {
      final response = await _dio.get('/activities/$activityId/lobby');
      return response.data ?? {'code': 500, 'msg': 'unknown error'};
    } catch (e) {
      print('getActivityLobbySnapshot error: $e');
      return {'code': 500, 'msg': '获取大厅快照失败: $e'};
    }
  }

  /// 大厅心跳
  static Future<Map<String, dynamic>> pingActivityLobby(int activityId) async {
    try {
      final response = await _dio.post(
        '/activities/$activityId/ping',
        options: await _authOptions(),
      );
      return response.data ?? {'code': 500, 'msg': 'unknown error'};
    } catch (e) {
      print('pingActivityLobby error: $e');
      return {'code': 500, 'msg': '心跳失败: $e'};
    }
  }

  /// 占位
  static Future<Map<String, dynamic>> reserveActivitySlot({
    required int activityId,
    required int courtNumber,
    required int slotNumber,
  }) async {
    try {
      final response = await _dio.post(
        '/activities/$activityId/reserve',
        data: {
          'courtNumber': courtNumber,
          'slotNumber': slotNumber,
        },
        options: await _authOptions(),
      );
      return response.data ?? {'code': 500, 'msg': 'unknown error'};
    } catch (e) {
      print('reserveActivitySlot error: $e');
      return {'code': 500, 'msg': '占位失败: $e'};
    }
  }

  /// 取消占位
  static Future<Map<String, dynamic>> cancelActivitySlot(int activityId) async {
    try {
      final response = await _dio.delete(
        '/activities/$activityId/reserve',
        options: await _authOptions(),
      );
      return response.data ?? {'code': 500, 'msg': 'unknown error'};
    } catch (e) {
      print('cancelActivitySlot error: $e');
      return {'code': 500, 'msg': '取消占位失败: $e'};
    }
  }

  /// 确认参加
  static Future<Map<String, dynamic>> confirmActivitySlot(int activityId) async {
    try {
      final response = await _dio.post(
        '/activities/$activityId/confirm',
        options: await _authOptions(),
      );
      return response.data ?? {'code': 500, 'msg': 'unknown error'};
    } catch (e) {
      print('confirmActivitySlot error: $e');
      return {'code': 500, 'msg': '确认参加失败: $e'};
    }
  }

  /// 发送大厅消息
  static Future<Map<String, dynamic>> sendActivityMessage({
    required int activityId,
    required String content,
  }) async {
    try {
      final response = await _dio.post(
        '/activities/$activityId/messages',
        data: {'content': content},
        options: await _authOptions(),
      );
      return response.data ?? {'code': 500, 'msg': 'unknown error'};
    } catch (e) {
      print('sendActivityMessage error: $e');
      return {'code': 500, 'msg': '发送消息失败: $e'};
    }
  }

  /// 离开大厅
  static Future<Map<String, dynamic>> leaveActivityLobby(int activityId) async {
    try {
      final response = await _dio.post(
        '/activities/$activityId/leave',
        options: await _authOptions(),
      );
      return response.data ?? {'code': 500, 'msg': 'unknown error'};
    } catch (e) {
      print('leaveActivityLobby error: $e');
      return {'code': 500, 'msg': '离开大厅失败: $e'};
    }
  }
}

class _MockConstants {
  static const List<String> mockCategories = [
    '技术交流', '球场推荐', '装备讨论', '赛事分享', '找球友', '吐槽大会',
  ];
  static const List<String> mockTitles = [
    '后场高球一直不到位怎么办？',
    '推荐一个超好打的室内球馆',
    '刚入手 VICTOR 神速 100X',
    '参加了区级双打比赛进了前八',
    '求组队！每周六下午 2-5 点',
    '为什么有些人打球只会吊网前',
    '分享一个练习步伐的方法',
    '尤尼克斯 85 克球拍手感评测',
    '比赛输了好沮丧对方发球太刁钻',
    '今天终于打了第一个完美吊球',
  ];
  static const List<String> mockContents = [
    '今天打球发现自己的后场高球一直不到位，有没有大神指导一下？',
    '推荐一个超好打的室内球馆，灯光充足地板不滑💪',
    '刚入手 VICTOR 神速 100X，手感真的比以前好太多！',
    '参加了区级双打比赛，进了前八，激动！',
    '求组队！每周六下午 2-5 点，南山区，双打为主，欢迎加入',
    '为什么有些人打球只会吊网前然后扑球？这玩法真的太无聊了...',
    '分享一个练习步伐的方法，每天 20 分钟，效果很明显',
    '尤尼克斯 85 克球拍手感很灵活，适合控球型选手',
    '比赛输了好沮丧，对方发球太刁钻，我根本接不住',
    '今天终于打了第一个完美吊球！',
  ];
}
