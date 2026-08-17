import 'package:flutter/foundation.dart';

/// 调试预览开关：true 时 Splash 跳过登录直接进主页（写入 mock 登录态）。
/// 默认 kDebugMode（浏览器/模拟器 debug 预览即生效）；测试里可置 false 验证真实登录跳转。
/// release 构建下 kDebugMode 恒为 false，登录流程不受影响。
bool devBypassLogin = kDebugMode;
