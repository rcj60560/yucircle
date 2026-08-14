# 羽联信息模块（Track A）设计稿

- 日期：2026-08-14
- 状态：已与用户逐节确认（范围/管道/视觉/布局）
- 关联：`doc/ROADMAP.md` Track A；视觉决策来自 brainstorm 可视化会话（`.superpowers/brainstorm/1029-*/content/`）

## 1. 背景与目标

羽球圈的内容抓手：**独家整合的羽联数据**——五个单项世界排名 + 世界巡回赛赛程。先让用户因为内容留下来，社区（Track B）并行。

数据结论（已探针验证）：
- 无可用的现成活库（SanderP99/Badminton-Data 已停更于 2025-01，但 MIT 爬虫代码可参考）。
- BWF 官网两个目标页均为服务端渲染、结构清晰、低频可爬：
  - 排名：`https://bwfworldtour.bwfbadminton.com/rankings/`（表格：排名/国家/选手/涨跌/积分，25 条/页）
  - 赛程：`https://bwfworldtour.bwfbadminton.com/calendar/`（全年赛程：日期/城市/级别/奖金/状态）

## 2. 范围

### v0 做
- 排名：男单/女单/男双/女双/混双 × Top 50（每项抓 2 页）
- 赛程：2026 世界巡回赛全季（Super 1000/750/500/300 + 总决赛）：日期、城市、级别、奖金；状态由日期推导（已结束/进行中/未开赛）
- 爬虫工具进用户工具箱（ky/tools 仓库），launcher 网页面板新增入口，爬完可浏览器预览
- App 新增「羽联」Tab（Tab1 默认落地），导航重排顺带隐藏球馆/俱乐部/大厅入口

### v0 不做（后续版本）
- 新闻、球员详情页、单场赛果/签表/对阵
- 往期赛季（站点支持情况未验证）
- 全自动定时（GitHub Actions 跨仓库推送需 PAT）——v0 手动/本地跑

## 3. 整体架构

```
【开发 & 预览】ky/tools 仓库（用户工具箱）
tools/<bwf-data>/                 ← 含 tool.toml，launcher 自动发现并注册入口
  ├─ tool.toml
  ├─ scraper.py                   ← 抓排名+赛程 → out/*.json
  ├─ preview_gen.py               ← 生成自包含 preview.html（数据内联）
  ├─ publish.py                   ← 拷贝 JSON 到 app 仓库并 commit+push
  ├─ config.toml                  ← app 仓库路径等本地配置
  └─ out/rankings.json, schedule.json

【分发】yucircle app 仓库
assets/data/bwf/rankings.json     ← 打包内置（离线/首次安装兜底）
assets/data/bwf/schedule.json
raw.githubusercontent.com/rcj60560/yucircle/main/assets/data/bwf/*.json ← 运行时刷新

【App】三层：Model 解析 → Service 取数（远端→本地缓存→内置）→ Page 渲染
```

## 4. 爬虫工具（ky/tools 仓库）

### 4.1 抓取规则
- 频率：**每周一次**（排名周四发布，建议周五跑）；赛程可同跑
- 请求头：常规浏览器 UA；超时 15s；失败重试 2 次（指数退避）
- 校验：输出行数异常（如某单项 < 40 行）即报错退出，不产出残缺 JSON
- 实现：Python + requests + BeautifulSoup；选择器参考 SanderP99/Badminton-Data（MIT）
- 排名分页：每单项抓前 2 页（Top 50）；单项切换/翻页的具体 URL 参数实现时从页面确认

### 4.2 JSON Schema

`rankings.json`：
```json
{
  "updatedAt": "2026-08-14T09:00:00+08:00",
  "source": "bwfworldtour.bwfbadminton.com",
  "disciplines": {
    "ms": { "name": "男单", "entries": [
      { "rank": 1, "change": 0, "country": "TPE",
        "player": "LIN Chun-Yi", "points": 30900 }
    ]},
    "ws": { "...": "同上" }, "md": {}, "wd": {}, "xd": {}
  }
}
```
双打 `player` 为两人名拼成的单个字符串（如 `LIANG Wei Keng / WANG Chang`），分隔符以页面实际格式为准，v0 原样展示。

`schedule.json`：
```json
{
  "updatedAt": "2026-08-14T09:00:00+08:00",
  "year": 2026,
  "tournaments": [
    { "name": "VICTOR China Open 2026",
      "startDate": "2026-07-21", "endDate": "2026-07-26",
      "city": "Changzhou, China",
      "level": "super1000",           // super1000|super750|super500|super300|finals|other
      "prizeMoney": 2000000 }
  ]
}
```
赛事状态**不落库**，App 端按当天日期推导（`endDate < 今天` = 已结束；区间内 = 进行中；否则未开赛）。

### 4.3 预览页
`preview_gen.py` 生成**自包含** `preview.html`（JSON 内联，双击即开）：顶部更新时间 + 两个区块（排名：单项 Tab + 表格；赛程：月度时间轴）。目的：爬完立刻在浏览器肉眼校验数据，满意再发布。

### 4.4 发布
`publish.py`：读取 `config.toml` 中 app 仓库路径 → 拷贝 `out/*.json` → `assets/data/bwf/` → git commit（`data: BWF 更新 YYYY-MM-DD`）+ push。发布前先跑 JSON 校验。

### 4.5 注册入口
`tool.toml`：name=羽联数据、desc、category=数据、status=ready、run.cmd=运行爬虫+生成预览。launcher 扫描目录以现有 `tools/` 统一布局为准（实现时确认 `tools_dir` 指向）。

## 5. App 端（yucircle 仓库）

### 5.1 新增文件
```
assets/data/bwf/rankings.json|schedule.json        （publish 产物）
lib/models/bwf_ranking.dart                        RankingDiscipline / RankingEntry
lib/models/bwf_schedule.dart                       Tournament / TournamentLevel / 推导状态
lib/services/bwf_data_service.dart                 取数三层 + shared_preferences 缓存
lib/pages/bwf/bwf_home_page.dart                   Tab1 容器：渐变头 + 排名|赛程 分段切换
lib/pages/bwf/bwf_rankings_page.dart               单项 chips + 徽章列表
lib/pages/bwf/bwf_schedule_page.dart               月度时间轴
```

### 5.2 数据服务（取数顺序）
1. 远端：Dio GET raw.githubusercontent 两个 JSON（5s 超时）
2. 成功 → 写入 shared_preferences 缓存（字符串），记录 updatedAt
3. 失败/无网 → 读本地缓存 → 再失败 → 读打包内置 asset
4. 页面展示「数据更新于 X」（三来源统一带 updatedAt）；下拉刷新强制走远端

### 5.3 导航重排（main_page.dart）
- Tab1：`VenueListPage` → `BwfHomePage`（球馆入口就此隐藏）
- 其余 Tab 不动（社区/发帖+/消息/我的）
- `main.dart` 中 `/venue-list`、`/club-list`、`/activity-lobby` 路由**保留注册但无 UI 入口**（代码不删，后续恢复只需换回 Tab1）

## 6. UI 规范（可视化会话已确认）

### 6.1 视觉方向：C 活力运动
- 渐变头：`linear-gradient(135deg, #00A868 → #0084C6)`，白字
- 背景 `#F4F7F5`；白色圆角卡（12-16px 圆角，浅投影 `rgba(0,132,198,.08~.16)`）
- 文字：主 `#14231D`，次 `#7C8F85`
- 涨 `#00A868 ▲`；进行中/警示 `#FF4D6D`
- 该组色值收敛为 `SportPalette` 常量入 `lib/config/theme.dart`（不动现有 AppTheme，全 App 视觉重构是后续独立事项）

### 6.2 排名页（用户已选定的列表形态）
- 头部：羽联 🏸 + 「世界排名 · 更新于 MM-DD」+ 排名|赛程 分段控件（默认排名）
- 单项 chips：男单（默认）/女单/男双/女双/混双，选中白底蓝字
- 行：排名徽章（1=金渐变 `#FFD76F→#E8A200`、2=银 `#D7DEE8`、3=铜 `#E8B48A`、其余裸数字）+ 国家码 + 选手名 + 涨跌 + 积分（等宽数字）

### 6.3 赛程页：A 月度时间轴（用户已选定）
- 左侧月份节点（当前/近期月绿底白字，其余白底描边），竖向连线
- 赛事卡：级别徽章 + 名称 + 日期·城市·奖金 + 状态（✓已结束 灰 / ●进行中 红 / 未开赛 蓝）
- **下一站**（最近一个未开赛）：卡片绿描边 `#00A868 2px` + 「▶ 下一站」标签
- 级别徽章色：S1000 金 / S750 `#E84D8A` / S500 `#2F7BFF` / S300 `#00A868` / Finals 黑底金字

## 7. 错误处理
- 远端失败 → 缓存 → 内置，三层兜底后仍无数据（理论不可能，内置必然存在）才显错误态
- JSON 解析失败按"该来源失败"处理走下一层
- 爬虫端：行数校验、结构变更（选择器失配）显式报错而非静默空数据

## 8. 测试策略
- 模型单测：fixture JSON → 解析断言（含双打名、状态推导边界：前一天/当天/后一天）
- 服务单测：注入 fake 取数器，验证 远端→缓存→内置 兜底顺序与缓存写入
- 页面冒烟：排名列表/时间轴渲染 widget 测试（小数据集）
- 爬虫端：对保存的 HTML 样本做解析单测（工具箱仓库内跑）

## 9. 风险与对策
| 风险 | 对策 |
|---|---|
| BWF 反爬/封禁 | 每周低频 + 正常 UA + 退避；被限流则换 corporate 站点源（SanderP 备用路径） |
| 站点改版导致选择器失效 | 行数校验报错；选择器集中在 scraper 单文件易修 |
| 版权（BWF 条款禁转载） | 个人学习用途；将来商业化需换商业 API（Sportradar 等）或授权——已记 ROADMAP |
| GitHub raw 在国内偶发不稳 | App 三层兜底已覆盖；后续可加后端中转作镜像（v1 选项） |

## 10. 交付顺序（给 writing-plans 拆任务用）
1. 爬虫 + 预览页（ky/tools 仓库，先用真实站验证 schema）
2. publish 脚本 + 首次数据落地 app 仓库 assets
3. App 模型 + 服务（含测试）
4. 羽联 Tab 三页面 + 导航重排（Tab1 换入口、球馆隐藏）
5. 收尾：更新 README/ROADMAP、真机过一遍
