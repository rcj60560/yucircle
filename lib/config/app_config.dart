class AppConfig {
  // 后端 API 地址（局域网 IP）
  static const String apiBaseUrl = 'http://192.168.13.74:8080/api';

  // Mock 模式开关：true = 本地 Mock，false = 请求真实后端
  static const bool mockMode = true;

  // Mock 短信验证码（mock 模式下固定）
  static const String mockSmsCode = '123456';

  static const String appName = '羽圈';
  static const String appVersion = '1.0.0';
}
