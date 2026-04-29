import 'package:get/get.dart';
import '../config/app_config.dart';
import '../utils/storage.dart';

/// Mock 模式下直接返回模拟数据，不发网络请求
class ApiClient {
  // ── 认证相关 ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> sendSmsCode(String phone) async {
    if (AppConfig.mockMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      return {'code': 0, 'msg': 'ok'};
    }
    // TODO: 真实 API
    throw UnimplementedError('real API not implemented yet');
  }

  static Future<Map<String, dynamic>> verifySmsCode(
      String phone, String code) async {
    if (AppConfig.mockMode) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (code == AppConfig.mockSmsCode) {
        return {
          'code': 0,
          'data': {
            'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
            'userId': 'user_001',
            'isNewUser': true,
          }
        };
      }
      return {'code': 1001, 'msg': '验证码错误'};
    }
    throw UnimplementedError('real API not implemented yet');
  }

  static Future<Map<String, dynamic>> setupProfile({
    required String nickname,
    required String level,
    required String phone,
  }) async {
    if (AppConfig.mockMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'code': 0,
        'data': {
          'userId': 'user_001',
          'nickname': nickname,
          'level': level,
          'phone': phone,
          'avatar': '',
        }
      };
    }
    throw UnimplementedError('real API not implemented yet');
  }

  // ── 帖子相关（占位，阶段3用）──────────────────────────────
  static Future<List<Map<String, dynamic>>> getPostList(
      {int page = 1, String category = '全部'}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.generate(
      10,
      (i) => {
        'id': 'post_$i',
        'nickname': '球友${i + 1}号',
        'avatar': '',
        'category': _MockConstants.mockCategories[i % _MockConstants.mockCategories.length],
        'content': _MockConstants.mockContents[i % _MockConstants.mockContents.length],
        'likeCount': (i + 1) * 3,
        'commentCount': i * 2,
        'createdAt': '2小时前',
      },
    );
  }
}

class _MockConstants {
  static const List<String> mockCategories = [
    '技术交流', '球场推荐', '装备讨论', '赛事分享', '找球友', '吐槽大会',
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
