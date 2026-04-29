class AppConfig {
  // 后端 API 地址（域名备案下来后替换）
  static const String apiBaseUrl = 'http://localhost:8080/api';

  // Mock 模式开关：true = 不请求真实后端，返回模拟数据
  static const bool mockMode = true;

  // Mock 短信验证码（mock 模式下固定）
  static const String mockSmsCode = '123456';

  static const String appName = '羽圈';
  static const String appVersion = '1.0.0';
}
