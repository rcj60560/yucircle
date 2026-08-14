# 羽联信息模块（Track A）实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 抓取 BWF 世界排名（5 单项×Top50）与 2026 巡回赛赛程，经 JSON 发布到 app 仓库，App 新增「羽联」Tab（活力运动风 UI）并隐藏球馆入口。

**Architecture:** 双仓库。ky/tools 工具箱仓库新增 `bwf-data` 爬虫工具（launcher 入口 + 预览页 + 发布脚本）；yucircle app 仓库新增内置 JSON 资产 + 模型/服务/页面，取数三层兜底（远端 raw → 本地缓存 → 内置）。Tab1 由球馆换为羽联。

**Tech Stack:** Python(requests+BeautifulSoup+pytest) / Flutter(GetX 路由、Dio、shared_preferences、flutter_test)

**Spec:** `docs/superpowers/specs/2026-08-14-bwf-info-design.md`

## Global Constraints

- **两个仓库**：app 仓库 `D:\Users\luocj\tf\yucircle\circle`（Task 5-9 在此提交）；工具箱仓库 `D:\Users\luocj\pyProject\ky\tools`（Task 1-4 在此提交，其 pytest 配置 `testpaths=["tests"]`，Python ≥3.10）。
- **User-Agent 必须逐字使用**（短 UA 会被 Cloudflare 403，已实测）：
  `Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36`
- **数据端点（已实测 200）**：
  - 排名 HTML：`https://bwfworldtour.bwfbadminton.com/rankings/`（无参 GET 返回 142B 的 JS 跳转，需解析出 `document.location='...'` 中的当前参数；`cat_id` 57/58/59/60/61 = 男单/女单/男双/女双/混双；单页即含 50 行；表格 class=`rankings-table`）
  - 赛程 JSON：`https://extranet-lv.bwfbadminton.com/api/vue-grouped-year-tournaments?year=2026`（带 `Accept: application/json` + `Referer: https://bwfworldtour.bwfbadminton.com/calendar/`）
- **JSON 字段名以 spec §4.2 为准，逐字使用**（rank/change/country/player/points；name/startDate/endDate/city/level/prizeMoney；level 取值 super1000|super750|super500|super300|finals|other）。
- Flutter **不新增依赖**（dio、shared_preferences 已有）；App 仓库代码风格：手写 fromJson 模型、StatefulWidget 页面、色值常量集中放 `lib/config/theme.dart`。
- 所有 commit message 末尾加：`Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`
- 工具箱仓库装依赖：`pip install requests beautifulsoup4`（Python 3.10 额外 `tomli`）。

---

### Task 1: 工具骨架 + 排名抓取（工具箱仓库）

**Files:**
- Create: `D:/Users/luocj/pyProject/ky/tools/tools/bwf-data/tool.toml`
- Create: `D:/Users/luocj/pyProject/ky/tools/tools/bwf-data/requirements.txt`
- Create: `D:/Users/luocj/pyProject/ky/tools/tools/bwf-data/scrape_rankings.py`
- Create: `D:/Users/luocj/pyProject/ky/tools/tests/fixtures/rankings_ms.html`
- Create: `D:/Users/luocj/pyProject/ky/tools/tests/fixtures/rankings_xd.html`
- Test: `D:/Users/luocj/pyProject/ky/tools/tests/test_bwf_rankings.py`

**Interfaces:**
- Consumes: 无（首任务）
- Produces: `scrape_rankings.py` 中 `parse_rankings_table(html: str) -> list[dict]`（dict 字段 rank/change/country/player/points，int/str 类型）、`scrape_rankings() -> dict`（spec §4.2 rankings.json 结构）、`OUT = Path(...)/out`、`http_get(url) -> str`（供 Task 2/3 复用）

- [ ] **Step 1: 建 fixture（真实表格结构，行结构来自实测）**

`tests/fixtures/rankings_ms.html`：

```html
<table width="100%" cellpadding="0" cellspacing="0" border="0" class="rankings-table">
  <tbody>
    <tr><th>RANK</th><th>COUNTRY</th><th>PLAYER</th><th>CHANGE</th><th>POINTS</th><th>BREAKDOWN</th></tr>
    <tr>
      <td align="center">1</td>
      <td align="center"><div class="country"><span>TPE</span><img class="flag" src="x.png"></div></td>
      <td class=""><div class="player"><a class="text-white" href="#">CHOU Tien Chen</a></div></td>
      <td align="center"><span class="ranking-change">0</span></td>
      <td align="center">67,710</td>
      <td align="center" class="breakdown"></td>
    </tr>
    <tr>
      <td align="center">2</td>
      <td align="center"><div class="country"><span>TPE</span><img class="flag" src="x.png"></div></td>
      <td class=""><div class="player"><a class="text-white" href="#">LIN Chun-Yi</a></div></td>
      <td align="center"><span class="ranking-change">0</span></td>
      <td align="center">30,900</td>
      <td align="center" class="breakdown"></td>
    </tr>
    <tr>
      <td align="center">5</td>
      <td align="center"><div class="country"><span>JPN</span><img class="flag" src="x.png"></div></td>
      <td class=""><div class="player"><a class="text-white" href="#">Yushi TANAKA</a></div></td>
      <td align="center"><span class="ranking-change">-5</span></td>
      <td align="center">25,110</td>
      <td align="center" class="breakdown"></td>
    </tr>
  </tbody>
</table>
```

`tests/fixtures/rankings_xd.html`（双打行：一个 td 内两个 `.player`）：

```html
<table class="rankings-table"><tbody>
  <tr><th>RANK</th><th>COUNTRY</th><th>PLAYER</th><th>CHANGE</th><th>POINTS</th><th>B</th></tr>
  <tr>
    <td align="center">1</td>
    <td align="center"><div class="country"><span>TPE</span></div></td>
    <td class=""><div class="player"><a href="#">WANG Chi-Lin</a></div><div class="player"><a href="#">LEE Jhe-Huei</a></div></td>
    <td align="center"><span class="ranking-change">0</span></td>
    <td align="center">70,000</td>
    <td></td>
  </tr>
</tbody></table>
```

- [ ] **Step 2: 写失败测试**

`tests/test_bwf_rankings.py`：

```python
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[1] / "tools" / "bwf-data"))
from scrape_rankings import parse_rankings_table

FIX = Path(__file__).parent / "fixtures"


def test_parse_singles():
    entries = parse_rankings_table((FIX / "rankings_ms.html").read_text(encoding="utf-8"))
    assert len(entries) == 3
    assert entries[0] == {"rank": 1, "change": 0, "country": "TPE",
                          "player": "CHOU Tien Chen", "points": 67710}
    assert entries[1]["points"] == 30900


def test_negative_change_keeps_sign():
    entries = parse_rankings_table((FIX / "rankings_ms.html").read_text(encoding="utf-8"))
    assert entries[2]["change"] == -5


def test_doubles_joined_with_slash():
    entries = parse_rankings_table((FIX / "rankings_xd.html").read_text(encoding="utf-8"))
    assert entries[0]["player"] == "WANG Chi-Lin / LEE Jhe-Huei"
```

- [ ] **Step 3: 跑测试确认失败**

Run（在 `D:/Users/luocj/pyProject/ky/tools` 下）: `python -m pytest tests/test_bwf_rankings.py -v`
Expected: FAIL —— `ModuleNotFoundError: No module named 'scrape_rankings'`

- [ ] **Step 4: 写实现**

`tools/tools/bwf-data/tool.toml`：

```toml
name = "羽联数据"
desc = "抓取 BWF 世界排名(5单项×Top50)与巡回赛赛程 → JSON → 发布到羽圈 App（附网页预览）"
category = "数据"
status = "ready"

[run]
cmd = ["python", "run_all.py"]
port = 0
url = ""

[links]
live = ""
```

`tools/tools/bwf-data/requirements.txt`：

```
requests>=2.31
beautifulsoup4>=4.12
tomli>=2.0; python_version < "3.11"
```

`tools/tools/bwf-data/scrape_rankings.py`：

```python
"""抓取 BWF 世界排名（5 单项 × Top 50）→ out/rankings.json"""
from __future__ import annotations

import json
import re
import time
from datetime import datetime, timezone
from pathlib import Path

import requests
from bs4 import BeautifulSoup

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
BASE = "https://bwfworldtour.bwfbadminton.com"
CAT_IDS = {"ms": 57, "ws": 58, "md": 59, "wd": 60, "xd": 61}
DISCIPLINE_NAMES = {"ms": "男单", "ws": "女单", "md": "男双", "wd": "女双", "xd": "混双"}
OUT = Path(__file__).parent / "out"


def http_get(url: str, accept: str = "text/html,application/xhtml+xml") -> str:
    """带完整 UA 的 GET；Cloudflare 拦截时退避重试（短 UA 必 403，勿改 UA）。"""
    for attempt in range(3):
        r = requests.get(url, headers={"User-Agent": UA, "Accept": accept}, timeout=15)
        if r.status_code == 200 and "cloudflare" not in r.text[:2000].lower():
            return r.text
        time.sleep(2 ** attempt)
    raise RuntimeError(f"fetch failed: {url}")


def resolve_current_params() -> str:
    """/rankings/ 无参 GET 返回 142B JS 跳转，解析出当前周参数串（id/cat_id/ryear/week/...）。"""
    m = re.search(r"document\.location='([^']+)'", http_get(BASE + "/rankings/"))
    if not m:
        raise RuntimeError("无法解析当前排名参数（页面结构可能已变化）")
    return m.group(1).split("?", 1)[1]


def parse_rankings_table(html: str) -> list[dict]:
    soup = BeautifulSoup(html, "html.parser")
    table = soup.find("table", class_="rankings-table")
    if table is None:
        raise RuntimeError("未找到 rankings-table（选择器失配）")
    entries: list[dict] = []
    for tr in table.find_all("tr"):
        tds = tr.find_all("td")
        if len(tds) < 6:
            continue
        rank_m = re.search(r"\d+", tds[0].get_text())
        if not rank_m:
            continue
        country_el = tds[1].select_one(".country span")
        players = [a.get_text(strip=True) for a in tds[2].select(".player a")]
        change_m = re.search(r"-?\d+", tds[3].get_text())
        points_m = re.search(r"[\d,]+", tds[4].get_text())
        if not players:
            continue
        entries.append({
            "rank": int(rank_m.group()),
            "change": int(change_m.group()) if change_m else 0,
            "country": country_el.get_text(strip=True) if country_el else "",
            "player": " / ".join(players),
            "points": int(points_m.group().replace(",", "")) if points_m else 0,
        })
        if len(entries) >= 50:
            break
    return entries


def scrape_rankings() -> dict:
    base_q = resolve_current_params()
    q = dict(pair.split("=", 1) for pair in base_q.split("&"))
    disciplines = {}
    for key, cat_id in CAT_IDS.items():
        q["cat_id"] = str(cat_id)
        url = BASE + "/rankings/?" + "&".join(f"{k}={v}" for k, v in q.items())
        entries = parse_rankings_table(http_get(url))
        if len(entries) < 40:
            raise RuntimeError(f"{key} 只解析到 {len(entries)} 行（阈值 40），中止以防残缺数据")
        disciplines[key] = {"name": DISCIPLINE_NAMES[key], "entries": entries}
        time.sleep(2)  # 礼貌间隔
    return {
        "updatedAt": datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds"),
        "source": "bwfworldtour.bwfbadminton.com",
        "disciplines": disciplines,
    }


def main() -> None:
    OUT.mkdir(exist_ok=True)
    data = scrape_rankings()
    (OUT / "rankings.json").write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding="utf-8")
    total = sum(len(d["entries"]) for d in data["disciplines"].values())
    print(f"OK rankings.json: 5 单项共 {total} 条")


if __name__ == "__main__":
    main()
```

- [ ] **Step 5: 跑测试确认通过**

Run: `python -m pytest tests/test_bwf_rankings.py -v`
Expected: 3 passed

- [ ] **Step 6: 真站验证**

Run: `cd tools/bwf-data && python -c "from scrape_rankings import parse_rankings_table, http_get, resolve_current_params, BASE, CAT_IDS; q = dict(p.split('=',1) for p in resolve_current_params().split('&')); q['cat_id']='57'; html = http_get(BASE + '/rankings/?' + '&'.join(f'{k}={v}' for k,v in q.items())); es = parse_rankings_table(html); print(len(es), es[0])"`
Expected: 打印 `50 {'rank': 1, ..., 'player': 'CHOU Tien Chen', ...}`（50 行；若双打行结构与 fixture 假设不符——即 `md/wd/xd` 的 player 无 `/`——按真实结构调整 `parse_rankings_table` 的 players 提取，重跑本步骤与 Step 5）

- [ ] **Step 7: 提交（工具箱仓库）**

```bash
cd /d/Users/luocj/pyProject/ky/tools
git add tools/bwf-data tests/fixtures/rankings_ms.html tests/fixtures/rankings_xd.html tests/test_bwf_rankings.py
git commit -m "feat(bwf-data): 排名抓取工具 — rankings-table 解析 + 当前周参数解析 + Cloudflare 对策

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: 赛程抓取（extranet-lv JSON API）

**Files:**
- Create: `D:/Users/luocj/pyProject/ky/tools/tools/bwf-data/scrape_schedule.py`
- Create: `D:/Users/luocj/pyProject/ky/tools/tests/fixtures/schedule_api.json`
- Test: `D:/Users/luocj/pyProject/ky/tools/tests/test_bwf_schedule.py`

**Interfaces:**
- Consumes: Task 1 的 `OUT` 常量
- Produces: `scrape_schedule.py` 中 `parse_schedule(payload: dict, year: int) -> dict`（spec §4.2 schedule.json 结构）、`level_from_category(category: str) -> str`、`scrape_schedule(year: int) -> dict`、`main(year: int | None = None)`

- [ ] **Step 1: 建 fixture（真实 API 响应节选）**

`tests/fixtures/schedule_api.json`：

```json
{"results": [
  {"month": "January", "monthNo": 1, "tournaments": [
    {"prize_money": "1,450,000", "start_date": "2026-01-06 00:00:00", "end_date": "2026-01-11 00:00:00",
     "name": "PETRONAS Malaysia Open 2026", "location": "Kuala Lumpur, Malaysia", "country": "Malaysia",
     "category": "HSBC BWF World Tour Super 1000"},
    {"prize_money": "-", "start_date": "2026-01-20 00:00:00", "end_date": "2026-01-25 00:00:00",
     "name": "Some International Challenge", "location": "Nowhere, Earth", "country": "Earth",
     "category": "BWF International Challenge"}
  ]},
  {"month": "December", "monthNo": 12, "tournaments": [
    {"prize_money": "3,500,000", "start_date": "2026-12-09 00:00:00", "end_date": "2026-12-13 00:00:00",
     "name": "HSBC BWF World Tour Finals 2026", "location": "Hangzhou, China", "country": "China",
     "category": "HSBC BWF World Tour Finals"}
  ]}
]}
```

- [ ] **Step 2: 写失败测试**

`tests/test_bwf_schedule.py`：

```python
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[1] / "tools" / "bwf-data"))
from scrape_schedule import parse_schedule, level_from_category

FIX = Path(__file__).parent / "fixtures"


def test_level_mapping():
    assert level_from_category("HSBC BWF World Tour Super 1000") == "super1000"
    assert level_from_category("HSBC BWF World Tour Super 750") == "super750"
    assert level_from_category("HSBC BWF World Tour Finals") == "finals"
    assert level_from_category("BWF International Challenge") == "other"


def test_parse_filters_and_sorts():
    payload = json.loads((FIX / "schedule_api.json").read_text(encoding="utf-8"))
    data = parse_schedule(payload, 2026)
    names = [t["name"] for t in data["tournaments"]]
    # 非 World Tour 被过滤；按 startDate 升序
    assert names == ["PETRONAS Malaysia Open 2026", "HSBC BWF World Tour Finals 2026"]
    first = data["tournaments"][0]
    assert first["level"] == "super1000"
    assert first["prizeMoney"] == 1450000
    assert first["startDate"] == "2026-01-06"
    assert data["year"] == 2026
```

- [ ] **Step 3: 跑测试确认失败**

Run: `python -m pytest tests/test_bwf_schedule.py -v`
Expected: FAIL —— `ModuleNotFoundError: No module named 'scrape_schedule'`

- [ ] **Step 4: 写实现**

`tools/tools/bwf-data/scrape_schedule.py`：

```python
"""抓取 BWF 世界巡回赛赛程（extranet-lv JSON API）→ out/schedule.json"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

import requests

from scrape_rankings import UA, OUT

API = "https://extranet-lv.bwfbadminton.com/api/vue-grouped-year-tournaments"
REFERER = "https://bwfworldtour.bwfbadminton.com/calendar/"
LEVELS = [
    ("World Tour Finals", "finals"),
    ("Super 1000", "super1000"),
    ("Super 750", "super750"),
    ("Super 500", "super500"),
    ("Super 300", "super300"),
]


def level_from_category(category: str) -> str:
    low = category.lower()
    for needle, level in LEVELS:
        if needle.lower() in low:
            return level
    return "other"


def parse_schedule(payload: dict, year: int) -> dict:
    tournaments = []
    for month in payload.get("results", []):
        for t in month.get("tournaments", []):
            level = level_from_category(t.get("category", ""))
            if level == "other":
                continue  # v0 只收 World Tour 级别（spec §2）
            prize = str(t.get("prize_money", "0")).replace(",", "")
            tournaments.append({
                "name": t["name"],
                "startDate": t["start_date"][:10],
                "endDate": t["end_date"][:10],
                "city": t.get("location", ""),
                "level": level,
                "prizeMoney": int(prize) if prize.isdigit() else 0,
            })
    tournaments.sort(key=lambda x: x["startDate"])
    return {
        "updatedAt": datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds"),
        "year": year,
        "tournaments": tournaments,
    }


def scrape_schedule(year: int) -> dict:
    r = requests.get(
        API,
        params={"year": year},
        headers={"User-Agent": UA, "Accept": "application/json", "Referer": REFERER},
        timeout=15,
    )
    r.raise_for_status()
    return parse_schedule(r.json(), year)


def main(year: int | None = None) -> None:
    year = year or datetime.now().year
    data = scrape_schedule(year)
    if len(data["tournaments"]) < 20:
        raise RuntimeError(f"只解析到 {len(data['tournaments'])} 站（阈值 20），中止")
    OUT.mkdir(exist_ok=True)
    (OUT / "schedule.json").write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"OK schedule.json: {year} 年 {len(data['tournaments'])} 站")


if __name__ == "__main__":
    main()
```

- [ ] **Step 5: 跑测试确认通过**

Run: `python -m pytest tests/test_bwf_schedule.py -v`
Expected: 2 passed

- [ ] **Step 6: 真站验证**

Run: `cd tools/bwf-data && python -c "from scrape_schedule import scrape_schedule; d = scrape_schedule(2026); print(len(d['tournaments'])); print(d['tournaments'][0]); print([t['name'] for t in d['tournaments'] if 'China Masters' in t['name']])"`
Expected: 打印 ≥20；第一站为 2026-01-06 Malaysia Open；含 `LI-NING China Masters 2026`（level super750、深圳）

- [ ] **Step 7: 提交（工具箱仓库）**

```bash
cd /d/Users/luocj/pyProject/ky/tools
git add tools/bwf-data/scrape_schedule.py tests/fixtures/schedule_api.json tests/test_bwf_schedule.py
git commit -m "feat(bwf-data): 赛程抓取 — extranet-lv JSON API，过滤 World Tour 级别并排序

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: 预览页 + 一键入口

**Files:**
- Create: `D:/Users/luocj/pyProject/ky/tools/tools/bwf-data/preview_gen.py`
- Create: `D:/Users/luocj/pyProject/ky/tools/tools/bwf-data/run_all.py`
- Test: `D:/Users/luocj/pyProject/ky/tools/tests/test_bwf_preview.py`

**Interfaces:**
- Consumes: Task 1 `scrape_rankings.main()`、Task 2 `scrape_schedule.main()`、两者共用的 `OUT`
- Produces: `preview_gen.build_page(rankings: dict, schedule: dict) -> str`、`preview_gen.main()`；`run_all.py` 命令行入口（`python run_all.py [--publish]`，`--publish` 在 Task 4 后可用）

- [ ] **Step 1: 写失败测试**

`tests/test_bwf_preview.py`：

```python
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[1] / "tools" / "bwf-data"))
from preview_gen import build_page

RANKINGS = {"updatedAt": "2026-08-14T09:00:00+08:00", "disciplines": {
    "ms": {"name": "男单", "entries": [{"rank": 1, "change": 0, "country": "TPE", "player": "CHOU Tien Chen", "points": 67710}]}}}
SCHEDULE = {"updatedAt": "2026-08-14T09:00:00+08:00", "year": 2026, "tournaments": [
    {"name": "LI-NING China Masters 2026", "startDate": "2026-09-01", "endDate": "2026-09-06",
     "city": "Shenzhen", "level": "super750", "prizeMoney": 1150000}]}


def test_preview_contains_data():
    html = build_page(RANKINGS, SCHEDULE)
    assert "CHOU Tien Chen" in html
    assert "LI-NING China Masters 2026" in html
    assert "2026-08-14" in html
    assert html.startswith("<!DOCTYPE html>")
```

- [ ] **Step 2: 跑测试确认失败**

Run: `python -m pytest tests/test_bwf_preview.py -v`
Expected: FAIL —— `ModuleNotFoundError: No module named 'preview_gen'`

- [ ] **Step 3: 写实现**

`tools/tools/bwf-data/preview_gen.py`：

```python
"""生成自包含预览页 out/preview.html（数据内联，双击即开，浏览器肉眼校验）"""
from __future__ import annotations

import json
from pathlib import Path

from scrape_rankings import OUT

PAGE = """<!DOCTYPE html><html lang="zh"><head><meta charset="utf-8">
<title>BWF 数据预览</title>
<style>
body{font-family:"Microsoft YaHei",sans-serif;background:#F4F7F5;margin:0;padding:20px;max-width:900px}
h1{background:linear-gradient(135deg,#00A868,#0084C6);-webkit-background-clip:text;background-clip:text;color:transparent;font-size:22px}
small{color:#7C8F85}
.tabs{display:flex;gap:8px;margin:12px 0;flex-wrap:wrap}
.tab{padding:6px 14px;border-radius:999px;background:#fff;cursor:pointer;font-size:13px}
.tab.on{background:#00A868;color:#fff}
table{border-collapse:collapse;width:100%;background:#fff;border-radius:12px;overflow:hidden}
td,th{padding:8px 12px;border-bottom:1px #eee solid;font-size:13px;text-align:left}
th{background:#f0f5f2}
.month{margin:18px 0 8px;font-weight:800;color:#0084C6}
.t{background:#fff;border-radius:12px;padding:10px 14px;margin:6px 0;box-shadow:0 2px 8px rgba(0,132,198,.08)}
.badge{font-size:11px;font-weight:800;color:#fff;border-radius:6px;padding:2px 8px;background:#0084C6}
</style></head><body>
<h1>🏸 BWF 数据预览</h1>
<small id="updated"></small>
<div class="tabs" id="tabs"></div><div id="rank"></div><div id="sched"></div>
<script>
const R = __RANKINGS__; const S = __SCHEDULE__;
document.getElementById('updated').textContent = '排名更新于 ' + (R.updatedAt||'') + ' · 赛程更新于 ' + (S.updatedAt||'');
const tabs = document.getElementById('tabs'); const rk = document.getElementById('rank');
let cur = 'ms';
function renderRank(){
  rk.innerHTML = '<table><tr><th>排名</th><th>国家</th><th>选手</th><th>涨跌</th><th>积分</th></tr>' +
    R.disciplines[cur].entries.map(e =>
      `<tr><td>${e.rank}</td><td>${e.country}</td><td>${e.player}</td><td>${e.change||'—'}</td><td>${e.points.toLocaleString()}</td></tr>`).join('') +
    '</table>';
}
Object.keys(R.disciplines).forEach(k => {
  const b = document.createElement('div'); b.className = 'tab'; b.textContent = R.disciplines[k].name;
  b.onclick = () => { cur = k; [...tabs.children].forEach(c => c.classList.remove('on')); b.classList.add('on'); renderRank(); };
  tabs.appendChild(b);
});
tabs.children[0].classList.add('on'); renderRank();
const months = {};
S.tournaments.forEach(t => { const m = t.startDate.slice(0, 7); (months[m] = months[m] || []).push(t); });
document.getElementById('sched').innerHTML = Object.keys(months).sort().map(m =>
  `<div class="month">${parseInt(m.slice(5), 10)}月</div>` + months[m].map(t =>
    `<div class="t"><span class="badge">${t.level}</span> <b>${t.name}</b><br>` +
    `<small>${t.startDate} ~ ${t.endDate} · ${t.city}${t.prizeMoney ? ' · $' + t.prizeMoney.toLocaleString() : ''}</small></div>`).join('')).join('');
</script></body></html>"""


def build_page(rankings: dict, schedule: dict) -> str:
    page = PAGE.replace("__RANKINGS__", json.dumps(rankings, ensure_ascii=False))
    return page.replace("__SCHEDULE__", json.dumps(schedule, ensure_ascii=False))


def main() -> None:
    rankings = json.loads((OUT / "rankings.json").read_text(encoding="utf-8"))
    schedule = json.loads((OUT / "schedule.json").read_text(encoding="utf-8"))
    (OUT / "preview.html").write_text(build_page(rankings, schedule), encoding="utf-8")
    print(f"OK 预览页: {OUT / 'preview.html'}")


if __name__ == "__main__":
    main()
```

`tools/tools/bwf-data/run_all.py`：

```python
"""一键：抓排名+赛程 → 生成预览页 →（可选 --publish 发布到羽圈 App 仓库）"""
from __future__ import annotations

import argparse
from pathlib import Path

import preview_gen
import scrape_rankings
import scrape_schedule


def main() -> None:
    parser = argparse.ArgumentParser(description="BWF 数据抓取/预览/发布")
    parser.add_argument("--publish", action="store_true", help="发布 JSON 到羽圈 App 仓库并 commit/push")
    args = parser.parse_args()

    scrape_rankings.main()
    scrape_schedule.main()
    preview_gen.main()
    print(f"浏览器打开查看: {Path(__file__).parent / 'out' / 'preview.html'}")
    if args.publish:
        import publish
        publish.main()


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: 跑测试确认通过**

Run: `python -m pytest tests/test_bwf_preview.py -v`
Expected: 1 passed

- [ ] **Step 5: 端到端跑一次 + 人工预览**

Run: `cd tools/bwf-data && python run_all.py`
Expected: 三行 OK 输出（rankings 250 条 / schedule ≥20 站 / 预览页路径）；用浏览器打开 `out/preview.html` 肉眼校验：五个单项 Tab 可切换、时间轴有 2026 各月、中国大师赛在深圳 9/1-9/6

- [ ] **Step 6: 提交（工具箱仓库）**

```bash
cd /d/Users/luocj/pyProject/ky/tools
git add tools/bwf-data/preview_gen.py tools/bwf-data/run_all.py tests/test_bwf_preview.py
git commit -m "feat(bwf-data): 自包含网页预览 + 一键入口 run_all.py

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: 发布脚本 + 首次数据落地 App 仓库

**Files:**
- Create: `D:/Users/luocj/pyProject/ky/tools/tools/bwf-data/config.toml`
- Create: `D:/Users/luocj/pyProject/ky/tools/tools/bwf-data/publish.py`
- Create（产物）: `D:/Users/luocj/tf/yucircle/circle/assets/data/bwf/rankings.json`、`schedule.json`
- Test: `D:/Users/luocj/pyProject/ky/tools/tests/test_bwf_publish.py`

**Interfaces:**
- Consumes: Task 1-3 的 `out/*.json`
- Produces: `publish.validate(rankings: dict, schedule: dict) -> None`（断言失败抛 AssertionError）、`publish.main(dry_run: bool = False)`；App 仓库 `assets/data/bwf/` 下两份真实数据（Task 5 起消费）

- [ ] **Step 1: 写失败测试**

`tests/test_bwf_publish.py`：

```python
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parents[1] / "tools" / "bwf-data"))
from publish import validate


def _rankings(n=50):
    return {"disciplines": {k: {"name": k, "entries": [{"rank": i} for i in range(n)]}
                            for k in ("ms", "ws", "md", "wd", "xd")}}


def _schedule(n=25):
    return {"year": 2026, "tournaments": [{"name": f"t{i}"} for i in range(n)]}


def test_validate_ok():
    validate(_rankings(), _schedule())  # 不抛即通过


def test_validate_missing_discipline():
    bad = _rankings(); bad["disciplines"].pop("xd")
    with pytest.raises(AssertionError):
        validate(bad, _schedule())


def test_validate_too_few_rows():
    with pytest.raises(AssertionError):
        validate(_rankings(n=10), _schedule())


def test_validate_too_few_tournaments():
    with pytest.raises(AssertionError):
        validate(_rankings(), _schedule(n=3))
```

- [ ] **Step 2: 跑测试确认失败**

Run: `python -m pytest tests/test_bwf_publish.py -v`
Expected: FAIL —— `ModuleNotFoundError: No module named 'publish'`

- [ ] **Step 3: 写实现**

`tools/tools/bwf-data/config.toml`（本地配置，含个人路径）：

```toml
# 羽圈 App 仓库（发布目标）
[app]
repo = "D:/Users/luocj/tf/yucircle/circle"
assets_dir = "assets/data/bwf"
```

`tools/tools/bwf-data/publish.py`：

```python
"""校验 out/*.json 并发布到羽圈 App 仓库（git add + commit + push）"""
from __future__ import annotations

import json
import shutil
import subprocess
import sys
from datetime import date
from pathlib import Path

if sys.version_info >= (3, 11):
    import tomllib
else:
    import tomli as tomllib

ROOT = Path(__file__).parent
OUT = ROOT / "out"


def load_config() -> dict:
    return tomllib.loads((ROOT / "config.toml").read_text(encoding="utf-8"))["app"]


def validate(rankings: dict, schedule: dict) -> None:
    assert set(rankings.get("disciplines", {})) == {"ms", "ws", "md", "wd", "xd"}, "排名缺少单项"
    for k, d in rankings["disciplines"].items():
        assert len(d["entries"]) >= 40, f"{k} 行数不足 40"
    assert len(schedule.get("tournaments", [])) >= 20, "赛程站数不足 20"


def main(dry_run: bool = False) -> None:
    rankings = json.loads((OUT / "rankings.json").read_text(encoding="utf-8"))
    schedule = json.loads((OUT / "schedule.json").read_text(encoding="utf-8"))
    validate(rankings, schedule)
    app = load_config()
    dest = Path(app["repo"]) / app["assets_dir"]
    dest.mkdir(parents=True, exist_ok=True)
    for name in ("rankings.json", "schedule.json"):
        shutil.copy(OUT / name, dest / name)
        print(f"copy {name} -> {dest / name}")
    if dry_run:
        print("dry-run：不执行 git 提交")
        return
    repo = app["repo"]
    subprocess.run(["git", "-C", repo, "add", app["assets_dir"]], check=True)
    subprocess.run(["git", "-C", repo, "commit", "-m", f"data: BWF 更新 {date.today().isoformat()}"], check=True)
    subprocess.run(["git", "-C", repo, "push"], check=False)  # 无网/凭据问题不中断，下次 push 即可
    print("OK 已发布到 App 仓库")


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: 跑测试确认通过**

Run: `python -m pytest tests/test_bwf_publish.py -v`
Expected: 4 passed

- [ ] **Step 5: 首次真发布**

Run: `cd tools/bwf-data && python run_all.py --publish`
Expected: 末尾输出 `OK 已发布到 App 仓库`；在 app 仓库 `git log --oneline -2` 看到 `data: BWF 更新 2026-08-14`（若 push 失败仅警告，不回滚；网络恢复后手动 `git push`）
⚠️ 注意：此步会在 App 仓库产生一次数据提交；Task 5 起 Flutter 端才能读到资产。

- [ ] **Step 6: 提交工具代码（工具箱仓库；App 仓库的数据提交由脚本自动完成，无需手动提交）**

```bash
cd /d/Users/luocj/pyProject/ky/tools
git add tools/bwf-data/publish.py tools/bwf-data/config.toml tests/test_bwf_publish.py
git commit -m "feat(bwf-data): 发布脚本 — 校验后拷贝 JSON 到羽圈 App 仓库并提交

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 5: App 数据模型 + 资产注册（App 仓库）

**Files:**
- Modify: `pubspec.yaml`（flutter: 段新增 assets）
- Create: `lib/models/bwf_ranking.dart`
- Create: `lib/models/bwf_schedule.dart`
- Test: `test/models/bwf_models_test.dart`

**Interfaces:**
- Consumes: Task 4 落地的 `assets/data/bwf/*.json`（schema 见 Global Constraints）
- Produces:
  - `RankingEntry{rank:int, change:int, country:String, player:String, points:int}`、`DisciplineRanking{key:String, name:String, entries:List<RankingEntry>}`、`RankingsData{updatedAt:DateTime, disciplines:Map<String,DisciplineRanking>}`，均含 `fromJson`
  - `enum TournamentLevel{super1000,super750,super500,super300,finals,other}`、`enum TournamentStatus{completed,ongoing,upcoming}`、`Tournament{name,startDate,endDate,city,level,prizeMoney}` + `Tournament.statusOn(DateTime today)`、`ScheduleData{year,updatedAt,tournaments}`

- [ ] **Step 1: 注册资产**

`pubspec.yaml` 的 `flutter:` 段（在 `uses-material-design: true` 之后加）：

```yaml
  uses-material-design: true

  assets:
    - assets/data/bwf/
```

- [ ] **Step 2: 写失败测试**

`test/models/bwf_models_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:yucircle/models/bwf_ranking.dart';
import 'package:yucircle/models/bwf_schedule.dart';

void main() {
  test('RankingsData.fromJson 解析与双打拼接', () {
    final data = RankingsData.fromJson({
      'updatedAt': '2026-08-14T09:00:00+08:00',
      'disciplines': {
        'ms': {
          'name': '男单',
          'entries': [
            {'rank': 1, 'change': 0, 'country': 'TPE', 'player': 'CHOU Tien Chen', 'points': 67710},
          ],
        },
        'xd': {
          'name': '混双',
          'entries': [
            {'rank': 1, 'change': -2, 'country': 'TPE', 'player': 'WANG Chi-Lin / LEE Jhe-Huei', 'points': 70000},
          ],
        },
      },
    });
    expect(data.disciplines.length, 2);
    final ms = data.disciplines['ms']!;
    expect(ms.name, '男单');
    expect(ms.entries.first.player, 'CHOU Tien Chen');
    expect(ms.entries.first.points, 67710);
    expect(data.disciplines['xd']!.entries.first.change, -2);
  });

  test('Tournament.level 映射与 statusOn 边界', () {
    final t = Tournament.fromJson({
      'name': 'LI-NING China Masters 2026',
      'startDate': '2026-09-01',
      'endDate': '2026-09-06',
      'city': 'Shenzhen',
      'level': 'super750',
      'prizeMoney': 1150000,
    });
    expect(t.level, TournamentLevel.super750);
    expect(t.prizeMoney, 1150000);
    expect(t.statusOn(DateTime(2026, 8, 31)), TournamentStatus.upcoming);
    expect(t.statusOn(DateTime(2026, 9, 1)), TournamentStatus.ongoing);
    expect(t.statusOn(DateTime(2026, 9, 6)), TournamentStatus.ongoing);
    expect(t.statusOn(DateTime(2026, 9, 7)), TournamentStatus.completed);
  });

  test('ScheduleData.fromJson 未知 level 归为 other', () {
    final s = ScheduleData.fromJson({
      'year': 2026,
      'tournaments': [
        {'name': 'x', 'startDate': '2026-01-01', 'endDate': '2026-01-02', 'city': '', 'level': 'whatever', 'prizeMoney': 0},
      ],
    });
    expect(s.year, 2026);
    expect(s.tournaments.first.level, TournamentLevel.other);
  });
}
```

- [ ] **Step 3: 跑测试确认失败**

Run（app 仓库根目录）: `flutter test test/models/bwf_models_test.dart`
Expected: FAIL —— `Error: Couldn't resolve the package 'yucircle' ...`（或文件不存在编译错）

- [ ] **Step 4: 写模型**

`lib/models/bwf_ranking.dart`：

```dart
/// BWF 世界排名数据模型（schema 见 docs/superpowers/specs/2026-08-14-bwf-info-design.md §4.2）
class RankingEntry {
  final int rank;
  final int change; // 正=上升 负=下降 0=持平
  final String country;
  final String player; // 双打为 "A / B" 单字符串
  final int points;

  const RankingEntry({
    required this.rank,
    required this.change,
    required this.country,
    required this.player,
    required this.points,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) => RankingEntry(
        rank: (json['rank'] as num).toInt(),
        change: (json['change'] as num? ?? 0).toInt(),
        country: json['country'] as String? ?? '',
        player: json['player'] as String? ?? '',
        points: (json['points'] as num? ?? 0).toInt(),
      );
}

class DisciplineRanking {
  final String key; // ms/ws/md/wd/xd
  final String name; // 男单/女单/男双/女双/混双
  final List<RankingEntry> entries;

  const DisciplineRanking({
    required this.key,
    required this.name,
    required this.entries,
  });

  factory DisciplineRanking.fromJson(String key, Map<String, dynamic> json) =>
      DisciplineRanking(
        key: key,
        name: json['name'] as String? ?? key,
        entries: ((json['entries'] as List?) ?? [])
            .map((e) => RankingEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class RankingsData {
  final DateTime updatedAt;
  final Map<String, DisciplineRanking> disciplines;

  const RankingsData({required this.updatedAt, required this.disciplines});

  factory RankingsData.fromJson(Map<String, dynamic> json) => RankingsData(
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime(2000),
        disciplines: (json['disciplines'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(
              k, DisciplineRanking.fromJson(k, Map<String, dynamic>.from(v as Map))),
        ),
      );
}
```

`lib/models/bwf_schedule.dart`：

```dart
/// BWF 世界巡回赛赛程模型；状态由日期推导，不落库
enum TournamentLevel { super1000, super750, super500, super300, finals, other }

enum TournamentStatus { completed, ongoing, upcoming }

class Tournament {
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String city;
  final TournamentLevel level;
  final int prizeMoney; // 0 = 未知（UI 不显示）

  const Tournament({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.city,
    required this.level,
    required this.prizeMoney,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
        name: json['name'] as String? ?? '',
        startDate:
            DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime(2000),
        endDate: DateTime.tryParse(json['endDate'] as String? ?? '') ?? DateTime(2000),
        city: json['city'] as String? ?? '',
        level: _levelFrom(json['level'] as String? ?? 'other'),
        prizeMoney: (json['prizeMoney'] as num? ?? 0).toInt(),
      );

  static TournamentLevel _levelFrom(String s) {
    switch (s) {
      case 'super1000':
        return TournamentLevel.super1000;
      case 'super750':
        return TournamentLevel.super750;
      case 'super500':
        return TournamentLevel.super500;
      case 'super300':
        return TournamentLevel.super300;
      case 'finals':
        return TournamentLevel.finals;
      default:
        return TournamentLevel.other;
    }
  }

  /// endDate < 今天 → completed；start~end 区间内 → ongoing；否则 upcoming
  TournamentStatus statusOn(DateTime today) {
    final d = DateTime(today.year, today.month, today.day);
    if (d.isAfter(endDate)) return TournamentStatus.completed;
    if (d.isBefore(startDate)) return TournamentStatus.upcoming;
    return TournamentStatus.ongoing;
  }
}

class ScheduleData {
  final int year;
  final DateTime updatedAt;
  final List<Tournament> tournaments; // 已按 startDate 升序（爬虫侧保证）

  const ScheduleData({
    required this.year,
    required this.updatedAt,
    required this.tournaments,
  });

  factory ScheduleData.fromJson(Map<String, dynamic> json) => ScheduleData(
        year: (json['year'] as num? ?? 0).toInt(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime(2000),
        tournaments: ((json['tournaments'] as List?) ?? [])
            .map((t) => Tournament.fromJson(Map<String, dynamic>.from(t as Map)))
            .toList(),
      );
}
```

- [ ] **Step 5: 跑测试确认通过**

Run: `flutter test test/models/bwf_models_test.dart`
Expected: 3 passed（若 `statusOn` 边界失败： startDate/endDate 由 `DateTime.tryParse('2026-09-01')` 得到当日 00:00，比较按天粒度，先核对测试日期再核对实现）

- [ ] **Step 6: 提交（App 仓库）**

```bash
cd /d/Users/luocj/tf/yucircle/circle
git add pubspec.yaml lib/models/bwf_ranking.dart lib/models/bwf_schedule.dart test/models/bwf_models_test.dart
git commit -m "feat(bwf): 排名/赛程数据模型 + 注册内置数据资产

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 6: BwfDataService 三层取数（App 仓库）

**Files:**
- Create: `lib/services/bwf_data_service.dart`
- Test: `test/services/bwf_data_service_test.dart`

**Interfaces:**
- Consumes: Task 5 的 `RankingsData.fromJson` / `ScheduleData.fromJson`；Task 4 的资产路径 `assets/data/bwf/*.json`
- Produces: `BwfDataService({Future<String?> Function(String url)? remoteFetcher, Future<String> Function(String path)? assetLoader})`，方法 `Future<RankingsData> loadRankings()`、`Future<ScheduleData> loadSchedule()`；raw 地址常量（raw.githubusercontent.com/rcj60560/yucircle/main/assets/data/bwf/...）

- [ ] **Step 1: 写失败测试**

`test/services/bwf_data_service_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yucircle/services/bwf_data_service.dart';

const _remoteJson = '{"updatedAt":"2026-08-14T09:00:00+08:00","disciplines":{"ms":{"name":"男单","entries":[{"rank":1,"change":0,"country":"TPE","player":"REMOTE","points":1}]}}}';
const _assetJson = '{"updatedAt":"2026-08-01T09:00:00+08:00","disciplines":{"ms":{"name":"男单","entries":[{"rank":1,"change":0,"country":"TPE","player":"ASSET","points":1}]}}}';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('远端成功 → 用远端并写缓存', () async {
    final svc = BwfDataService(
      remoteFetcher: (url) async => _remoteJson,
      assetLoader: (path) async => _assetJson,
    );
    final data = await svc.loadRankings();
    expect(data.disciplines['ms']!.entries.first.player, 'REMOTE');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('bwf_rankings_cache'), _remoteJson);
  });

  test('远端失败且无缓存 → 用内置 asset', () async {
    final svc = BwfDataService(
      remoteFetcher: (url) async => null,
      assetLoader: (path) async => _assetJson,
    );
    final data = await svc.loadRankings();
    expect(data.disciplines['ms']!.entries.first.player, 'ASSET');
  });

  test('远端失败但有缓存 → 用缓存', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bwf_rankings_cache', _remoteJson);
    final svc = BwfDataService(
      remoteFetcher: (url) async => null,
      assetLoader: (path) async => _assetJson,
    );
    final data = await svc.loadRankings();
    expect(data.disciplines['ms']!.entries.first.player, 'REMOTE');
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/services/bwf_data_service_test.dart`
Expected: FAIL —— 编译错误（bwf_data_service.dart 不存在）

- [ ] **Step 3: 写实现**

`lib/services/bwf_data_service.dart`：

```dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bwf_ranking.dart';
import '../models/bwf_schedule.dart';

/// BWF 数据取数：远端 raw JSON → 本地缓存 → 打包内置 asset（spec §5.2）
class BwfDataService {
  static const _base =
      'https://raw.githubusercontent.com/rcj60560/yucircle/main/assets/data/bwf';
  static const _rankingsUrl = '$_base/rankings.json';
  static const _scheduleUrl = '$_base/schedule.json';
  static const _rankingsCacheKey = 'bwf_rankings_cache';
  static const _scheduleCacheKey = 'bwf_schedule_cache';

  /// 测试注入口
  final Future<String?> Function(String url)? remoteFetcher;
  final Future<String> Function(String assetPath)? assetLoader;

  BwfDataService({this.remoteFetcher, this.assetLoader});

  Future<RankingsData> loadRankings() async => RankingsData.fromJson(
      await _load(_rankingsUrl, _rankingsCacheKey, 'assets/data/bwf/rankings.json'));

  Future<ScheduleData> loadSchedule() async => ScheduleData.fromJson(
      await _load(_scheduleUrl, _scheduleCacheKey, 'assets/data/bwf/schedule.json'));

  Future<Map<String, dynamic>> _load(
      String url, String cacheKey, String assetPath) async {
    // 1) 远端（成功则写缓存）
    try {
      final remote = await (remoteFetcher != null
          ? remoteFetcher!(url)
          : _dioGet(url));
      if (remote != null && remote.isNotEmpty) {
        (await SharedPreferences.getInstance()).setString(cacheKey, remote);
        return Map<String, dynamic>.from(jsonDecode(remote) as Map);
      }
    } catch (_) {/* 落到下一层 */}
    // 2) 本地缓存
    final cached = (await SharedPreferences.getInstance()).getString(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      return Map<String, dynamic>.from(jsonDecode(cached) as Map);
    }
    // 3) 内置资产
    final bundled =
        await (assetLoader != null ? assetLoader!(assetPath) : rootBundle.loadString(assetPath));
    return Map<String, dynamic>.from(jsonDecode(bundled) as Map);
  }

  Future<String?> _dioGet(String url) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final r = await dio.get<String>(url);
      return r.statusCode == 200 ? r.data : null;
    } catch (_) {
      return null;
    }
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/services/bwf_data_service_test.dart`
Expected: 3 passed

- [ ] **Step 5: 提交（App 仓库）**

```bash
cd /d/Users/luocj/tf/yucircle/circle
git add lib/services/bwf_data_service.dart test/services/bwf_data_service_test.dart
git commit -m "feat(bwf): 三层取数服务 — 远端raw → 本地缓存 → 内置资产

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 7: SportPalette + 羽联 Tab 容器 + 排名页（App 仓库）

**Files:**
- Modify: `lib/config/theme.dart`（文件末尾追加 SportPalette 类）
- Create: `lib/pages/bwf/bwf_home_page.dart`
- Create: `lib/pages/bwf/bwf_rankings_page.dart`
- Test: `test/pages/bwf_rankings_page_test.dart`

**Interfaces:**
- Consumes: Task 5 模型、Task 6 `BwfDataService`
- Produces:
  - `SportPalette`（静态色值常量：`green/blue/bg/textPrimary/textSecondary/danger/gold/goldDark/silver/bronze/levelS750/levelS500` + `headerGradient`）
  - `BwfHomePage`（无参构造，供 Task 9 放入 Tab1）
  - `BwfRankingsPage({required RankingsData data})`

- [ ] **Step 1: SportPalette 追加到 theme.dart**

在 `lib/config/theme.dart` 文件末尾追加：

```dart

/// 羽联模块（BWF）「活力运动」配色 —— spec §6.1，视觉决策来自可视化会话
class SportPalette {
  static const Color green = Color(0xFF00A868);
  static const Color blue = Color(0xFF0084C6);
  static const Color bg = Color(0xFFF4F7F5);
  static const Color textPrimary = Color(0xFF14231D);
  static const Color textSecondary = Color(0xFF7C8F85);
  static const Color danger = Color(0xFFFF4D6D);
  static const Color gold = Color(0xFFFFD76F);
  static const Color goldDark = Color(0xFFE8A200);
  static const Color silver = Color(0xFFD7DEE8);
  static const Color bronze = Color(0xFFE8B48A);
  static const Color levelS750 = Color(0xFFE84D8A);
  static const Color levelS500 = Color(0xFF2F7BFF);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [green, blue],
  );
}
```

- [ ] **Step 2: 写失败测试**

`test/pages/bwf_rankings_page_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yucircle/models/bwf_ranking.dart';
import 'package:yucircle/pages/bwf/bwf_rankings_page.dart';

RankingsData _data() => RankingsData.fromJson({
      'updatedAt': '2026-08-14T09:00:00+08:00',
      'disciplines': {
        'ms': {
          'name': '男单',
          'entries': List.generate(
            5,
            (i) => {
              'rank': i + 1,
              'change': i == 0 ? 2 : 0,
              'country': 'TPE',
              'player': '选手${i + 1}号',
              'points': 60000 - i * 100,
            },
          ),
        },
      },
    });

void main() {
  testWidgets('排名页渲染选手与单项chip', (tester) async {
    await tester.pumpWidget(MaterialApp(home: BwfRankingsPage(data: _data())));
    expect(find.text('选手1号'), findsOneWidget);
    expect(find.text('选手5号'), findsOneWidget);
    expect(find.text('男单'), findsOneWidget);
  });
}
```

- [ ] **Step 3: 跑测试确认失败**

Run: `flutter test test/pages/bwf_rankings_page_test.dart`
Expected: FAIL —— 编译错误（页面不存在）

- [ ] **Step 4: 写页面**

`lib/pages/bwf/bwf_home_page.dart`：

```dart
import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/bwf_ranking.dart';
import '../../models/bwf_schedule.dart';
import '../../services/bwf_data_service.dart';
import 'bwf_rankings_page.dart';
import 'bwf_schedule_page.dart';

/// 羽联 Tab：渐变头 + 排名|赛程 分段（spec §6.2/6.3）
class BwfHomePage extends StatefulWidget {
  const BwfHomePage({super.key});

  @override
  State<BwfHomePage> createState() => _BwfHomePageState();
}

class _BwfHomePageState extends State<BwfHomePage> {
  final _service = BwfDataService();
  int _section = 0; // 0 排名 1 赛程
  RankingsData? _rankings;
  ScheduleData? _schedule;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await _service.loadRankings();
      final s = await _service.loadSchedule();
      if (mounted) {
        setState(() {
          _rankings = r;
          _schedule = s;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '数据加载失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SportPalette.bg,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: const BoxDecoration(gradient: SportPalette.headerGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '羽联 🏸',
                      style: TextStyle(
                          color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Text(
                      '数据更新于 ${_updatedLabel()}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(children: [_segment('排名', 0), _segment('赛程', 1)]),
                ),
              ],
            ),
          ),
          Expanded(
            child: _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!,
                          style: const TextStyle(color: SportPalette.textSecondary)),
                    ),
                  )
                : _rankings == null || _schedule == null
                    ? const Center(
                        child: CircularProgressIndicator(color: SportPalette.green))
                    : RefreshIndicator(
                        color: SportPalette.green,
                        onRefresh: _load,
                        child: _section == 0
                            ? BwfRankingsPage(data: _rankings!)
                            : BwfSchedulePage(data: _schedule!),
                      ),
          ),
        ],
      ),
    );
  }

  String _updatedLabel() {
    final d = _section == 0 ? _rankings?.updatedAt : _schedule?.updatedAt;
    if (d == null || d.year <= 2000) return '—';
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$m-$day';
  }

  Widget _segment(String label, int index) {
    final on = _section == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _section = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: on ? SportPalette.blue : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
```

`lib/pages/bwf/bwf_rankings_page.dart`：

```dart
import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/bwf_ranking.dart';

const _disciplineOrder = ['ms', 'ws', 'md', 'wd', 'xd'];

/// 排名页：单项 chips + 徽章列表（spec §6.2）
class BwfRankingsPage extends StatefulWidget {
  final RankingsData data;

  const BwfRankingsPage({super.key, required this.data});

  @override
  State<BwfRankingsPage> createState() => _BwfRankingsPageState();
}

class _BwfRankingsPageState extends State<BwfRankingsPage> {
  String _current = 'ms';

  @override
  Widget build(BuildContext context) {
    final keys =
        _disciplineOrder.where((k) => widget.data.disciplines.containsKey(k)).toList();
    final discipline = widget.data.disciplines[_current] ??
        widget.data.disciplines[keys.first]!;

    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              for (final k in keys)
                _chip(k, discipline: widget.data.disciplines[k]!.name),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            itemCount: discipline.entries.length,
            itemBuilder: (context, i) => _row(discipline.entries[i]),
          ),
        ),
      ],
    );
  }

  Widget _chip(String key, {required String discipline}) {
    final on = _current == key;
    return GestureDetector(
      onTap: () => setState(() => _current = key),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: on ? Colors.white : SportPalette.green.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? SportPalette.green : Colors.transparent),
        ),
        child: Text(
          discipline,
          style: TextStyle(
            fontSize: 13,
            fontWeight: on ? FontWeight.w800 : FontWeight.w500,
            color: on ? SportPalette.blue : SportPalette.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _row(RankingEntry e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x140084C6), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          _rankBadge(e.rank),
          const SizedBox(width: 8),
          Text(
            e.country,
            style: const TextStyle(fontSize: 10, color: SportPalette.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              e.player,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: SportPalette.textPrimary),
            ),
          ),
          _changeLabel(e.change),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            child: Text(
              e.points.toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: SportPalette.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankBadge(int rank) {
    Color? bg;
    if (rank == 1) bg = SportPalette.goldDark;
    if (rank == 2) bg = SportPalette.silver;
    if (rank == 3) bg = SportPalette.bronze;
    if (bg != null) {
      return Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: bg),
        child: Text('$rank',
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
      );
    }
    return SizedBox(
      width: 24,
      child: Text('$rank',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: SportPalette.textPrimary)),
    );
  }

  Widget _changeLabel(int change) {
    if (change > 0) {
      return Text('▲$change',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SportPalette.green));
    }
    if (change < 0) {
      return Text('▼${-change}',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SportPalette.danger));
    }
    return const Text('—',
        style: TextStyle(fontSize: 10, color: SportPalette.textSecondary));
  }
}
```

（注意：`bwf_home_page.dart` 引用了 Task 8 的 `BwfSchedulePage`，本任务先创建占位文件 `bwf_schedule_page.dart`，内容为 `import 'package:flutter/material.dart';\nimport '../../models/bwf_schedule.dart';\n\nclass BwfSchedulePage extends StatelessWidget {\n  final ScheduleData data;\n  const BwfSchedulePage({super.key, required this.data});\n  @override\n  Widget build(BuildContext context) =>\n      const Center(child: Text('赛程页（Task 8 实现）'));\n}`，Task 8 覆写为完整实现。）

- [ ] **Step 5: 跑测试确认通过 + 静态检查**

Run: `flutter test test/pages/bwf_rankings_page_test.dart && flutter analyze lib/pages/bwf lib/config/theme.dart`
Expected: 1 passed；analyze 无 error（warning 允许）

- [ ] **Step 6: 提交（App 仓库）**

```bash
cd /d/Users/luocj/tf/yucircle/circle
git add lib/config/theme.dart lib/pages/bwf test/pages/bwf_rankings_page_test.dart
git commit -m "feat(bwf): 羽联Tab容器(渐变头+分段) + 排名徽章列表 + SportPalette 配色

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 8: 赛程时间轴页（App 仓库）

**Files:**
- Modify: `lib/pages/bwf/bwf_schedule_page.dart`（覆写 Task 7 的占位）
- Test: `test/pages/bwf_schedule_page_test.dart`

**Interfaces:**
- Consumes: Task 5 `Tournament/TournamentLevel/TournamentStatus/ScheduleData`
- Produces: `BwfSchedulePage({required ScheduleData data})`（容器/签名与 Task 7 占位一致）

- [ ] **Step 1: 写失败测试**

`test/pages/bwf_schedule_page_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yucircle/models/bwf_schedule.dart';
import 'package:yucircle/pages/bwf/bwf_schedule_page.dart';

ScheduleData _data() => ScheduleData.fromJson({
      'year': 2026,
      'tournaments': [
        {
          'name': 'LI-NING China Masters 2026',
          'startDate': '2026-09-01',
          'endDate': '2026-09-06',
          'city': 'Shenzhen',
          'level': 'super750',
          'prizeMoney': 1150000,
        },
        {
          'name': 'PETRONAS Malaysia Open 2026',
          'startDate': '2026-01-06',
          'endDate': '2026-01-11',
          'city': 'Kuala Lumpur',
          'level': 'super1000',
          'prizeMoney': 1450000,
        },
      ],
    });

void main() {
  testWidgets('时间轴渲染赛事、月份与下一站标记', (tester) async {
    await tester.pumpWidget(MaterialApp(home: BwfSchedulePage(data: _data())));
    expect(find.text('LI-NING China Masters 2026'), findsOneWidget);
    expect(find.text('PETRONAS Malaysia Open 2026'), findsOneWidget);
    expect(find.text('9月'), findsWidgets);
    expect(find.text('▶ 下一站'), findsOneWidget);
    expect(find.text('S750'), findsOneWidget);
    expect(find.text('S1000'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/pages/bwf_schedule_page_test.dart`
Expected: FAIL —— 找不到 '▶ 下一站' / 'S750'（占位页只渲染一行文本）

- [ ] **Step 3: 覆写实现**

`lib/pages/bwf/bwf_schedule_page.dart` 全文替换为：

```dart
import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/bwf_schedule.dart';

/// 赛程页：月度时间轴 + 级别徽章 + 下一站高亮（spec §6.3）
class BwfSchedulePage extends StatelessWidget {
  final ScheduleData data;

  const BwfSchedulePage({super.key, required this.data});

  (Color, String) _levelStyle(TournamentLevel l) {
    switch (l) {
      case TournamentLevel.super1000:
        return (SportPalette.goldDark, 'S1000');
      case TournamentLevel.super750:
        return (SportPalette.levelS750, 'S750');
      case TournamentLevel.super500:
        return (SportPalette.levelS500, 'S500');
      case TournamentLevel.super300:
        return (SportPalette.green, 'S300');
      case TournamentLevel.finals:
        return (SportPalette.textPrimary, 'FINALS');
      case TournamentLevel.other:
        return (SportPalette.textSecondary, '其他');
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final next = data.tournaments
        .where((t) => t.statusOn(now) == TournamentStatus.upcoming)
        .toList();

    // 按开赛月分组（保持升序）
    final groups = <String, List<Tournament>>{};
    for (final t in data.tournaments) {
      final key = '${t.startDate.year}-${t.startDate.month.toString().padLeft(2, '0')}';
      (groups[key] ??= []).add(t);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: groups.length,
      itemBuilder: (context, gi) {
        final key = groups.keys.elementAt(gi);
        final month = int.parse(key.split('-')[1]);
        final isNextMonth =
            next.isNotEmpty && next.first.startDate.month == month;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧月份轴
            SizedBox(
              width: 44,
              child: Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isNextMonth ? SportPalette.green : Colors.white,
                      border: Border.all(
                          color: isNextMonth ? SportPalette.green : const Color(0xFFE1EAE4),
                          width: 2),
                    ),
                    child: Text('$month月',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isNextMonth
                                ? Colors.white
                                : SportPalette.textPrimary)),
                  ),
                  if (gi != groups.length - 1)
                    Container(width: 2, height: _groupHeight(groups[key]!), color: const Color(0xFFD5E3DB)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 右侧赛事卡
            Expanded(
              child: Column(
                children: [
                  for (final t in groups[key]!) _card(t, isNext: identical(t, next.isNotEmpty ? next.first : null)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // 粗略估高让连线不断档：每张卡 ~78
  double _groupHeight(List<Tournament> list) => list.length * 84.0 + 8;

  Widget _card(Tournament t, {required bool isNext}) {
    final (color, label) = _levelStyle(t.level);
    final status = t.statusOn(DateTime.now());
    final (statusText, statusColor) = switch (status) {
      TournamentStatus.completed => ('✓ 已结束', SportPalette.textSecondary),
      TournamentStatus.ongoing => ('● 进行中', SportPalette.danger),
      TournamentStatus.upcoming => ('未开赛', SportPalette.blue),
    };
    final range =
        '${t.startDate.month}/${t.startDate.day} - ${t.endDate.month}/${t.endDate.day}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x140084C6), blurRadius: 8, offset: Offset(0, 2)),
        ],
        border: isNext ? Border.all(color: SportPalette.green, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: color),
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const Spacer(),
              if (isNext)
                const Text('▶ 下一站',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w800, color: SportPalette.green))
              else
                Text(statusText,
                    style: TextStyle(fontSize: 10, color: statusColor)),
            ],
          ),
          const SizedBox(height: 6),
          Text(t.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: SportPalette.textPrimary)),
          const SizedBox(height: 4),
          Text(
            '$range · ${t.city}${t.prizeMoney > 0 ? ' · \$${_fmt(t.prizeMoney)}' : ''}',
            style: const TextStyle(fontSize: 11, color: SportPalette.textSecondary),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    var s = n.toString();
    final buf = StringBuffer();
    while (s.length > 3) {
      buf.write(',${s.substring(s.length - 3)}');
      s = s.substring(0, s.length - 3);
    }
    return '$s$buf';
  }
}
```

注意：`_groupHeight` 只是连线长度估算（非精确），视觉容差可接受；若测试因布局溢出失败，把 `ListView` 换成 `SingleChildScrollView + Column` 并去掉 `_groupHeight` 相关行、连线用 `IntrinsicHeight` 包裹。

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/pages/bwf_schedule_page_test.dart`
Expected: 1 passed

- [ ] **Step 5: 提交（App 仓库）**

```bash
cd /d/Users/luocj/tf/yucircle/circle
git add lib/pages/bwf/bwf_schedule_page.dart test/pages/bwf_schedule_page_test.dart
git commit -m "feat(bwf): 赛程月度时间轴 — 级别徽章/状态推导/下一站高亮

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 9: 导航重排（Tab1 换羽联、球馆隐藏）+ 收尾

**Files:**
- Modify: `lib/pages/main/main_page.dart:4`（import）、`:24-30`（_pages[0]）、`:63-68`（Tab1 文案图标）
- Modify: `doc/ROADMAP.md`（Track A 状态）
- Test: 现有全部测试 + `flutter analyze`

**Interfaces:**
- Consumes: Task 7 `BwfHomePage`
- Produces: 新导航（Tab1 羽联/Tab2 社区/Tab3 发帖+/Tab4 消息/Tab5 我的）；`/venue-list` 等路由保留注册但无 UI 入口（spec §5.3）

- [ ] **Step 1: 改导航**

`lib/pages/main/main_page.dart` 三处修改：

1) 第 4 行 `import '../venue/venue_list_page.dart';` 替换为 `import '../bwf/bwf_home_page.dart';`

2) `_pages` 列表第一项 `const VenueListPage(),      // Tab1: 球馆列表` 替换为 `const BwfHomePage(),         // Tab1: 羽联（球馆入口已隐藏，代码保留）`

3) Tab1 的 `BottomNavigationBarItem`：`icon: Icon(Icons.sports)` / `activeIcon: Icon(Icons.sports)` 保留，`label: '球馆'` 改为 `label: '羽联'`

- [ ] **Step 2: 全量验证**

Run: `flutter analyze && flutter test`
Expected: analyze 无 error；全部测试 passed（含既有测试）

- [ ] **Step 3: 真机/模拟器人工过一遍**

Run: `flutter run`
检查单（逐条确认）：
- [ ] 底部 5 Tab：羽联（默认落地，渐变头+排名列表）｜社区｜＋｜消息｜我的
- [ ] 排名页 5 个单项 chip 可切换，Top3 有金银铜徽章，涨跌 ▲▼ 正确
- [ ] 赛程页按月时间轴，下一站绿框高亮，级别徽章颜色正确
- [ ] 断网重开 App 仍能显示数据（内置资产兜底）
- [ ] 无任何入口能进到球馆/俱乐部/大厅页面

- [ ] **Step 4: 更新 ROADMAP + 提交（App 仓库）**

`doc/ROADMAP.md` Track A 状态行改为：

```markdown
- 状态：🚧 已实现（数据管道 + 羽联 Tab），spec/plan 见 docs/superpowers/，每周 `python run_all.py --publish` 更新数据
```

```bash
cd /d/Users/luocj/tf/yucircle/circle
git add lib/pages/main/main_page.dart doc/ROADMAP.md
git commit -m "feat(bwf): Tab1 换羽联入口，球馆/俱乐部/大厅导航入口隐藏（代码保留）

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## 计划自审记录

- **Spec 覆盖**：§2 范围（T1/T2 抓取、T9 隐藏入口）、§3 管道（T1-T4 工具箱、T5-T6 App 取数）、§4 爬虫与 schema（T1/T2/T4 校验阈值 40/20）、§5 App 端（T5 模型、T6 服务、T7/T8 页面、T9 导航）、§6 UI（T7/T8 色值与布局按已确认 mockup）、§7 错误处理（T6 三层兜底、T1/T2 行数校验）、§8 测试（各任务 TDD + T9 全量）、§9 风险（UA/退避在 T1，行数校验防残缺）——全覆盖。
- **占位符扫描**：无 TBD/TODO；Task 7 对 `bwf_schedule_page.dart` 的占位文件是显式跨任务接口约定（Task 8 覆写），非未完成项。
- **类型一致性**：`parse_rankings_table/parse_schedule/build_page/validate` 与各自测试一致；Dart 侧 `RankingsData/ScheduleData/Tournament.statusOn/BwfDataService.loadRankings/loadSchedule` 在 T5-T8 引用与定义一致；`BwfSchedulePage` 签名 T7 占位与 T8 实现一致。
