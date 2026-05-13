# Phase 4 球馆俱乐部活动大厅 - 集成测试清单 & 客户端开发指南

**文档版本**: 1.0  
**完成日期**: 2026-05-12  
**目标受众**: Flutter 客户端开发者  
**服务端状态**: ✅ 已就绪 (Port 8080, Context Path: `/api`)

---

## 📋 一、API 端点快速检查表

所有端点均已实现并通过编译验证。

### 场馆端点 (Venue)
- ✅ `GET /api/venues` - 获取所有球馆列表

### 俱乐部端点 (Club)
- ✅ `GET /api/clubs/venue/{venueId}` - 获取指定球馆的俱乐部列表（含实时统计）
- ✅ `POST /api/clubs` - 创建新俱乐部
- ✅ `GET /api/clubs/{clubId}` - 获取俱乐部详情

### 活动端点 (Activity) - **核心业务**
- ✅ `POST /api/activities` - 创建活动
- ✅ `POST /api/activities/{activityId}/enter` - 进入大厅（初始化用户presence）
- ✅ `GET /api/activities/{activityId}/lobby` - **重点端点** 获取大厅快照（包含场地、人员、消息、广播）
- ✅ `POST /api/activities/{activityId}/ping` - 心跳（保活用户状态）
- ✅ `POST /api/activities/{activityId}/leave` - 离开大厅（清理presence和slot）
- ✅ `POST /api/activities/{activityId}/reserve` - 预订场地（1个用户占1个slot）
- ✅ `DELETE /api/activities/{activityId}/reserve` - 取消场地预订
- ✅ `POST /api/activities/{activityId}/confirm` - 确认场地（准备比赛）
- ✅ `POST /api/activities/{activityId}/messages` - 发送大厅消息（60秒速率限制）
- ✅ `GET /api/activities/{activityId}/messages` - 获取消息列表（已包含在lobby快照中）

### 广播端点 (Broadcast)
- ✅ `GET /api/broadcasts/active` - 获取活跃广播（按俱乐部过滤）
- ✅ `POST /api/broadcasts/clubs/{clubId}` - 发送俱乐部广播

---

## 🔐 二、身份认证 (JWT Token)

所有 **需要用户身份** 的端点（POST/DELETE/写操作）都需要 JWT Token。

### Token 格式
```
Authorization: Bearer {token}
```

### 获取 Token
1. **登录** (已实现但文档外，假设已有) → 获得 JWT Token
2. **Token 有效期**: 24 小时 (86400000 毫秒)
3. **Token 结构**: 用户ID encoded in JWT subject

### 使用示例（Flutter）
```dart
final token = "your_jwt_token_here";
final headers = {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
};

// 进入活动大厅
final response = await http.post(
  Uri.parse('http://localhost:8080/api/activities/1/enter'),
  headers: headers,
);
```

---

## 🧪 三、集成测试场景 (从简到复杂)

### 场景 A: 基础大厅查询 (无需登录)
**目标**: 验证场馆、俱乐部、活动数据的可读性

```
1. GET /api/venues
   ✅ 验证: 返回 200, 包含 "晴天羽毛球馆" (courtCount=10)

2. GET /api/clubs/venue/1
   ✅ 验证: 返回 3 个俱乐部 (A/B/C)
   ✅ 统计: todayActivityCount > 0, onlineCount 实时更新

3. GET /api/activities/1/lobby (未登录)
   ✅ 验证: 返回大厅快照，包含:
      - 10 个 court 对象
      - 每个 court 有 6 个 slot (empty/reserved/confirmed/locked 状态)
      - 0 个 observers (初始)
      - 0 条消息 (初始)
      - broadcasts 列表
```

### 场景 B: 单用户进入大厅 (需要登录)
**目标**: 验证用户presence管理和心跳

```
前提条件:
- 用户1已登录，获得 JWT token
- 活动1已存在

步骤:
1. POST /api/activities/1/enter (header: Authorization: Bearer token)
   ✅ 返回: Activity 对象
   ✅ 副作用: 在 activity_presence 表中创建用户1的 presence 记录

2. GET /api/activities/1/lobby
   ✅ 验证: onlineCount = 1, 显示用户1的信息

3. 每2秒 POST /api/activities/1/ping (保活)
   ✅ 验证: 用户1的 last_ping_at 时间戳更新
   ✅ 保证: 30 秒未 ping 将被自动移除

4. POST /api/activities/1/leave (离开)
   ✅ 验证: 用户1从 presence 表中删除
   ✅ 验证: onlineCount 回到 0
```

### 场景 C: 场地预订流程 (核心业务)
**目标**: 验证1对1用户-场地绑定、确认、锁定

```
前提条件:
- 用户1/2/3/4/5/6 已进入活动1大厅
- 都在不断 ping

步骤 1: 用户1预订场地1
POST /api/activities/1/reserve
Body: {
  "courtNumber": 1,  // 球场编号 (1-10)
  "slotNumber": 1    // 位置编号 (1-6，每个球场最多6人)
}
✅ 返回: ActivitySlotDto {id, courtNumber, slotNumber, userId, slotStatus: "reserved"}
✅ 副作用: 
   - slot status 变为 "reserved"
   - slot.user_id = 1
   - slot.lock_expires_at = now + 3分钟

✅ 验证大厅快照:
   GET /api/activities/1/lobby
   → courts[0].slots[0] = {userId: 1, status: "reserved", userName: "用户1", level: "中级"}

步骤 2: 用户2-6 也预订 (总共6人占满球场1)
POST /api/activities/1/reserve (用户2-6 分别调用)
✅ 每个用户占据不同的 slotNumber (2-6)

✅ 验证:
   GET /api/activities/1/lobby
   → courts[0] 显示 6 个 occupied slots

步骤 3: 所有6人确认 (表示都准备好开始比赛)
POST /api/activities/1/confirm (用户1调用)
✅ 返回: ActivitySlotDto {slotStatus: "confirmed"}
✅ 副作用: 
   - slot status 变为 "confirmed"
   - 如果球场1的6个 slot 都是 confirmed → 球场自动 LOCKED

POST /api/activities/1/confirm (用户2-6 分别调用)
✅ 最后一个确认时，球场自动锁定

✅ 最终验证:
   GET /api/activities/1/lobby
   → courts[0].status = "locked" 
   → 所有 slots[0-5] status = "confirmed"
   → UI 应显示: "成局" 或绿色锁定标记

步骤 4: 清理 (用户1离开)
POST /api/activities/1/leave
✅ 副作用: 删除 presence，AND 调用 cancelSlot 清理 reserved slot
```

### 场景 D: 多球场并行预订
**目标**: 验证多个球场可独立管理

```
步骤:
1. 用户1-6 预订球场1 (同场景C)
2. 用户7-12 预订球场2
3. 用户13-18 预订球场3

✅ 验证 GET /api/activities/1/lobby:
   - courts[0] = 6人已确认，locked ✓
   - courts[1] = 6人已预订/确认中 ✓
   - courts[2] = 6人已预订/确认中 ✓
   - courts[3-9] = 全空 ✓

✅ 验证场地独立性:
   - 用户1取消不影响球场2
   - 球场2确认不影响球场3
```

### 场景 E: 大厅消息与速率限制
**目标**: 验证60秒速率限制生效

```
前提条件:
- 用户1已在活动1大厅

步骤 1: 第一条消息 (应成功)
POST /api/activities/1/messages
Body: { "content": "大家好！" }
✅ 返回: 201 或 200
✅ GET /api/activities/1/lobby 显示消息

步骤 2: 立即第二条消息 (应被拒绝)
POST /api/activities/1/messages
Body: { "content": "又一条！" }
❌ 返回: 429 (Too Many Requests) 或类似错误
✅ 验证: "请在60秒后重试" 提示

步骤 3: 60秒后再发一条 (应成功)
Wait 60 seconds...
POST /api/activities/1/messages
Body: { "content": "60秒过了！" }
✅ 返回: 200, 发送成功

✅ 验证 GET /api/activities/1/lobby:
   → messages 列表包含 ["大家好！", "60秒过了！"]
```

### 场景 F: 广播消息
**目标**: 验证俱乐部级别广播

```
前提条件:
- 用户1是俱乐部A的创建者（或有权限）

步骤 1: 发送广播
POST /api/broadcasts/clubs/1
Body: {
  "title": "今晚7点集合！",
  "content": "所有俱乐部成员在大厅集合",
  "expiryMinutes": 60  // 1小时后过期
}
✅ 返回: Broadcast 对象

步骤 2: 验证大厅中看到广播
GET /api/activities/1/lobby (活动属于俱乐部1)
✅ 响应中 broadcasts 列表包含刚发送的广播

步骤 3: 过期验证（可选）
Wait 61 minutes...
POST /api/activities/1/leave (重新进入)
GET /api/activities/1/lobby
✅ broadcasts 列表应不包含过期广播
```

### 场景 G: 自动清理任务
**目标**: 验证后台定时任务

```
验证运行的定时任务:
1. cleanupExpiredPresence (每10秒检查一次，30秒超时)
   - 用户离线后30秒未ping → 自动删除presence
   
2. cleanupExpiredSlots (每30秒检查一次，180秒超时)
   - reserved slot 超过3分钟 → 自动释放
   
3. cleanupOldMessages (每1小时检查一次，>1天)
   - 超过1天的消息 → 自动删除
   
4. cleanupExpiredBroadcasts (每5分钟检查一次)
   - 过期的广播 → 自动删除

测试方法:
1. 用户进入 → ping → 停止ping
2. 等待 35 秒
3. GET /api/activities/1/lobby
   ✅ 用户不再出现在 onlineCount 中
```

---

## 📱 四、客户端开发检查清单

完成以下任务，确保与服务端完全兼容：

### 4.1 Tab 导航 & 基础查询
- [ ] 修复 WLAN Tab 结构，跳转到俱乐部列表
- [ ] `GET /venues` → 显示场馆列表（下拉刷新）
- [ ] `GET /clubs/venue/{venueId}` → 显示俱乐部列表，展示:
  - [ ] 俱乐部名称
  - [ ] 今日活动数 (todayActivityCount)
  - [ ] 在线人数 (onlineCount)
  - [ ] 是否有广播标记 (hasBroadcast)

### 4.2 活动大厅基础功能
- [ ] 点击俱乐部 → 进入活动列表
- [ ] 选择活动 → 显示大厅页面
- [ ] `POST /activities/{id}/enter` 获取 JWT Token 并进入
- [ ] `GET /activities/{id}/lobby` 显示完整大厅界面，包含:
  - [ ] 10 个球场网格 (CourtGrid)
  - [ ] 每个球场的6个位置格子
  - [ ] 空位显示灰色，已占用显示用户头像+昵称+水平

### 4.3 心跳机制
- [ ] 进入大厅 → 启动 Timer
- [ ] **每2秒** `POST /activities/{id}/ping` (需要 JWT Token)
- [ ] 用户离开或应用后台 → 停止 ping 并 `POST /activities/{id}/leave`
- [ ] 处理 ping 失败 → 重试或提示用户离线

### 4.4 场地预订流程
- [ ] 用户点击空位 → 打开预订对话框
- [ ] 选择位置 → `POST /activities/{id}/reserve` {courtNumber, slotNumber}
- [ ] 成功 → 位置变为蓝色 "已预订"，显示用户头像
- [ ] 显示预订倒计时 (180秒)：
  - [ ] 60秒内 → 显示 "即将锁定"
  - [ ] 30秒内 → 显示 "快到期" (红色警告)
  - [ ] 过期 → 位置清空

### 4.5 确认机制
- [ ] 位置状态 "reserved" 时显示 "确认" 按钮
- [ ] 点击确认 → `POST /activities/{id}/confirm`
- [ ] 成功 → 位置变为深蓝色 "已确认"
- [ ] 当球场6个位置全部 "confirmed" → 显示 "成局 ✓"，背景变绿

### 4.6 消息功能
- [ ] 大厅底部显示消息列表（ScrollView）
- [ ] 输入框 → 输入消息 → 点击发送
- [ ] `POST /activities/{id}/messages` {content}
- [ ] 发送失败时:
  - [ ] 429 → 显示 "发送过于频繁，请在60秒后重试"
  - [ ] 其他错误 → 显示通用错误提示
- [ ] 消息按时间排序，显示:
  - [ ] 用户头像
  - [ ] 用户昵称
  - [ ] 消息内容
  - [ ] 时间戳 (HH:mm)

### 4.7 广播显示
- [ ] 大厅顶部显示 "广播条" (如果有活跃广播)
- [ ] 点击广播 → 弹出详情框
- [ ] 显示:
  - [ ] 广播标题
  - [ ] 广播内容
  - [ ] 发布时间
  - [ ] 过期时间

### 4.8 离开处理
- [ ] "离开大厅" 按钮 → `POST /activities/{id}/leave`
- [ ] 关闭 ping Timer
- [ ] 清理预订的场地 (自动发生，服务端处理)
- [ ] 返回俱乐部列表或场馆列表

### 4.9 异常处理
- [ ] 网络超时 → 显示重试按钮
- [ ] JWT Token 过期 → 跳转登录
- [ ] 用户被踢出 (presence 清理) → 显示 "您已离线"
- [ ] 服务器错误 (500) → 显示 "服务器异常，请稍后重试"

### 4.10 UI 优化
- [ ] 球场网格响应式布局 (2x5 或其他)
- [ ] 用户头像显示为圆形
- [ ] 水平等级用颜色标记（低=绿，中=蓝，高=红）
- [ ] 场地预订倒计时用进度条显示
- [ ] 消息时间戳相对时间显示 ("1分钟前")

---

## 🔧 五、关键技术注意事项

### 5.1 JWT Token 管理
```dart
// ✅ 最佳实践：在进入大厅时保存 token
String token = await _getValidToken(); // 从登录界面或存储获取
final headers = {'Authorization': 'Bearer $token'};

// ❌ 避免：重复请求获取 token
// ✅ 改进：缓存 token，定期验证有效期
```

### 5.2 轮询间隔
```dart
// ✅ 每2秒轮询一次大厅快照
Timer.periodic(Duration(seconds: 2), (timer) {
  _getLobbySnapshot(activityId);
});

// ❌ 不要每1秒轮询（浪费资源）
// ❌ 不要每5秒轮询（用户体验差）
```

### 5.3 心跳 vs 轮询
```
心跳 (ping): POST /activities/{id}/ping
- 目的: 保持用户在线状态
- 频率: 每2-5秒一次
- 负载: 很小（仅更新时间戳）

轮询 (lobby): GET /activities/{id}/lobby
- 目的: 获取实时场地、人员、消息状态
- 频率: 每2秒一次
- 负载: 中等（返回整个大厅状态）

✅ 推荐: 同时进行，ping 可以稍频繁，lobby 保持2秒
```

### 5.4 状态转移图
```
用户进入大厅:
  ↓
presence created (在线)
  ↓
用户预订场地:
  ↓
slot.status = "reserved" (3分钟倒计时)
  ↓ (用户确认 OR 倒计时过期)
  ├→ confirmed (等待其他人)
  └→ empty (倒计时结束自动释放)
  ↓
所有6个 slot confirmed:
  ↓
court.status = "locked" (成局！)
  ↓
用户离开:
  ↓
presence deleted + slot canceled + cleanup
```

---

## 📊 六、监控指标

测试时记录以下数据：

| 指标 | 目标值 | 备注 |
|-----|-------|------|
| 大厅快照响应时间 | < 200ms | 包括网络往返时间 |
| ping 成功率 | > 99% | 心跳不应失败 |
| 消息发送延迟 | < 500ms | 用户可感知的延迟 |
| 并发用户数 | ≥ 100 | 单个活动 |
| 场地预订确认延迟 | < 1s | UI 更新延迟 |

---

## 🚀 七、快速开始 (开发者指南)

### 开发环境设置
1. 确保服务端运行在 `localhost:8080`
2. 修改 `lib/config/api_config.dart`:
   ```dart
   const String BASE_URL = 'http://localhost:8080/api';
   ```
3. 确保 GetX 已配置用于 HTTP 请求

### 示例代码片段

#### 进入大厅
```dart
Future<void> _enterLobby(int activityId) async {
  try {
    String token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('$BASE_URL/activities/$activityId/enter'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      _currentActivity = Activity.fromJson(data['data']);
      _startHeartbeat(activityId);
    } else {
      _showError('进入大厅失败');
    }
  } catch (e) {
    _showError('网络错误: $e');
  }
}
```

#### 获取大厅快照
```dart
Future<void> _getLobbySnapshot(int activityId) async {
  try {
    final response = await http.get(
      Uri.parse('$BASE_URL/activities/$activityId/lobby'),
    );
    
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      var lobby = ActivityLobbyDto.fromJson(data['data']);
      
      // 更新 UI
      _updateLobbyUI(lobby);
    }
  } catch (e) {
    // 处理异常，但不中断 UI
  }
}
```

#### 预订场地
```dart
Future<void> _reserveSlot(int activityId, int courtNum, int slotNum) async {
  try {
    String token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('$BASE_URL/activities/$activityId/reserve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'courtNumber': courtNum,
        'slotNumber': slotNum,
      }),
    );
    
    if (response.statusCode == 200) {
      Get.snackbar('成功', '已预订场地！');
      _startSlotCountdown(activityId, courtNum, slotNum);
    } else {
      Get.snackbar('失败', '预订失败，请重试');
    }
  } catch (e) {
    Get.snackbar('错误', '网络异常');
  }
}
```

---

## 📝 八、已知限制 & 后续改进

### 当前版本限制
1. **WebSocket 未使用**: 目前使用轮询，建议后续升级为 WebSocket 实时推送
2. **消息保存**: 仅保存当天消息，历史消息不可查
3. **用户信息**: 目前 JWT 中仅包含 ID，详细信息需额外查询
4. **文件上传**: 暂不支持图片/视频，仅文本消息

### 后续优化方向
1. **实时通知**: WebSocket → 实时推送场地变化、消息
2. **视频直播**: 集成直播流，支持比赛录制
3. **积分系统**: 比赛结果统计，玩家排名
4. **支付集成**: 场地费用结算

---

## 🎯 九、验收标准

### Level 1: 基础验收 (必须)
- [ ] 所有 13 个 API 端点能够正常调用
- [ ] 单用户能完整走通进入→预订→确认→离开流程
- [ ] 消息发送与速率限制生效
- [ ] JWT 身份验证生效

### Level 2: 多用户验收 (推荐)
- [ ] 多用户同时预订不同球场
- [ ] 6人确认后球场自动锁定
- [ ] 用户离线后 presence 自动清理
- [ ] 场地预订超时自动释放

### Level 3: 压力测试 (可选)
- [ ] 50 个并发用户进入同一活动
- [ ] 每秒 100 条消息处理
- [ ] 平均响应时间 < 500ms

---

## 📞 十、问题排查 (Troubleshooting)

### 问题1: 连接拒绝 (Connection Refused)
```
症状: 无法连接到 localhost:8080
排查:
1. 确认服务端运行: ps aux | grep java
2. 检查端口占用: netstat -an | grep 8080
3. 尝试: curl http://localhost:8080/api/venues
```

### 问题2: JWT Token 过期
```
症状: 返回 401 Unauthorized
排查:
1. 检查 token 有效期: 24 小时
2. 重新登录获取新 token
3. 验证 Authorization header 格式: "Bearer {token}"
```

### 问题3: 场地预订失败
```
症状: 返回 400 或 409 Conflict
排查:
1. 检查 courtNumber 是否在 1-10 范围内
2. 检查 slotNumber 是否在 1-6 范围内
3. 检查该位置是否已被占用
```

### 问题4: 消息发送频繁限制
```
症状: 返回 429 或类似错误
解决:
1. 正常现象，60秒内仅允许1条消息
2. 提示用户: "请在 {剩余时间} 秒后重试"
3. 可针对不同用户独立计时 (后端支持)
```

---

## 📚 十一、参考资源

- [Spring Boot 官方文档](https://spring.io/projects/spring-boot)
- [MyBatis-Plus 文档](https://baomidou.com)
- [Flutter HTTP 请求](https://flutter.dev/docs/cookbook/networking/fetch-data)
- [GetX 状态管理](https://github.com/jonataslaw/getx)
- [JWT 详解](https://jwt.io/)

---

## 📌 十二、签名

| 角色 | 姓名 | 完成日期 | 备注 |
|-----|-----|---------|------|
| 服务端开发 | Copilot | 2026-05-12 | 所有端点已实现、编译、初步测试 |
| 客户端开发 | 待定 | 待定 | 按照此清单完成 Flutter 实现 |
| QA | 待定 | 待定 | 完整的集成测试 |

---

**文档结束**

_更新记录:_
- v1.0 (2026-05-12): 初版发布，包含所有13个API端点、7个测试场景、4级客户端检查清单
