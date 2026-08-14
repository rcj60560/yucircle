# 羽圈 YuCircle

面向羽毛球爱好者的 App：**独家整合的羽球信息（排名 / 赛程 / 资讯）** + **球友社区**。

> 状态：重构中。先用「独家羽球信息」做抓手吸引用户，社区并行（发帖先 mock 简单可用）。

## 仓库结构（前后端分离）

| 仓库 | 说明 | 路径 |
|---|---|---|
| **yucircle（本仓库）** | Flutter App（前端） | `D:\Users\luocj\tf\yucircle\circle` |
| **yucircle-server** | Spring Boot 后端（独立仓库） | `D:\Users\luocj\tf\yu-server\server\yucircle-server` · [github.com/rcj60560/yucircle-server](https://github.com/rcj60560/yucircle-server) |

后端保持独立仓库、不做 git 耦合，详见 [doc/BACKEND.md](doc/BACKEND.md)。

## 技术栈
- 前端：Flutter · GetX（路由 / 状态）· Dio（网络）· shared_preferences
- 后端：Spring Boot 3 · MyBatis-Plus · JWT · MySQL 8

## 运行
- **连真实后端**：启动 `yucircle-server`，`lib/config/app_config.dart` 设 `mockMode = false`、`apiBaseUrl` 指向后端地址，`flutter run`。
- **mock 模式**：`mockMode = true` 可脱离后端运行（社区 / 登录的 mock 收口在 Track B 进行中）。

## 文档
- 路线图：[doc/ROADMAP.md](doc/ROADMAP.md)
- 后端关联：[doc/BACKEND.md](doc/BACKEND.md)
- 功能设计稿：`docs/superpowers/specs/`（brainstorming 产物）
- 旧文档（球馆大厅等暂停模块）：[doc/archive/](doc/archive/)

## 开发流程（superpowers 范式）
每个功能：`brainstorming`（澄清需求 / 方案）→ 写 spec 到 `docs/superpowers/specs/` → `writing-plans` 出实现计划 → 实现。
