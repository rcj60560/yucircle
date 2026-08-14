# 后端关联说明

前后端**分离**，各自独立仓库，**不做 git 耦合**（不用 submodule）。

## 后端仓库

| 项 | 值 |
|---|---|
| 名称 | yucircle-server |
| 本地路径 | `D:\Users\luocj\tf\yu-server\server\yucircle-server` |
| 远程 | https://github.com/rcj60560/yucircle-server.git |
| 技术栈 | Spring Boot 3 · Gradle · MyBatis-Plus · JWT · MySQL 8 |
| 已实现 | 认证（短信验证码）、论坛帖子 / 评论 / 点赞、球馆俱乐部活动大厅 |

## 启动后端

```bash
cd D:/Users/luocj/tf/yu-server/server/yucircle-server
./gradlew bootRun
```

默认监听 `:8080`。App 的 API 地址在 `lib/config/app_config.dart` 的 `apiBaseUrl`。

## 前后端如何「关联」

- **数据**：全部存在后端 MySQL，App 通过 REST API 读写。
- **契约**：改接口时同步改 App 的 `lib/services/api_client.dart`；接口约定记录在各功能 spec 里。
- **开发体验（可选）**：用 `.code-workspace` 把前后端两个仓库放进同一个 VSCode 窗口，方便同时改。

## App 端配置（`lib/config/app_config.dart`）

| 字段 | 作用 |
|---|---|
| `apiBaseUrl` | 后端地址（局域网 IP，按实际机器改） |
| `mockMode` | `true` = 脱离后端独立运行；`false` = 连真实后端 |
| `mockSmsCode` | mock 模式下的固定验证码 |

> 已知问题：mock 模式下 `sendSmsCode` 返回 `code:0` 而 `AuthController` 判断 `code==200`，导致发验证码失败——将在 Track B（社区 mock）中修复。
