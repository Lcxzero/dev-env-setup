---
name: find-skill
description: 技能发现工具 - 在技能仓库中搜索和发现可用的AI Agent技能。当用户需要查找特定功能的技能、按关键词/分类搜索技能、或了解技能仓库中的可用技能时使用此技能。Use ONLY when the user asks to find, search for, or discover skills in the skill repository.
---

# 技能发现工具

在技能仓库中搜索和发现可用的 AI Agent 技能。

## 何时使用

- 查找特定功能的技能
- 按关键词搜索技能
- 按分类浏览技能
- 列出所有可用的技能
- 查看技能详情和描述

## 技能仓库位置

```
/home/lcxzero/repos/skill/
```

## 搜索技能

### 按名称或描述搜索

```bash
# 搜索包含关键词的技能
grep -r "关键词" /home/lcxzero/repos/skill/data/skills.json

# 搜索本地技能
grep -r "关键词" /home/lcxzero/repos/skill/data/local_skills.json

# 搜索技能目录
find /home/lcxzero/repos/skill/skills -name "SKILL.md" -exec grep -l "关键词" {} \;
```

### 列出所有本地技能

```bash
ls /home/lcxzero/repos/skill/skills/
```

### 查看技能列表数据

```bash
# 官方技能（182个）
cat /home/lcxzero/repos/skill/data/skills.json | python3 -m json.tool | less

# 本地技能（66个）
cat /home/lcxzero/repos/skill/data/local_skills.json | python3 -m json.tool | less
```

### 按分类查找

```bash
# 列出所有分类
python3 -c "
import json
with open('/home/lcxzero/repos/skill/data/local_skills.json') as f:
    d = json.load(f)
for cat in d.get('categories', {}).keys():
    print(cat)
"
```

## 查看技能详情

```bash
# 读取 SKILL.md 获取技能详细信息
cat /home/lcxzero/repos/skill/skills/{skill-name}/*/SKILL.md

# 列出技能目录结构
ls -la /home/lcxzero/repos/skill/skills/{skill-name}/
```

## 技能分类

| 分类 | 数量 | 示例 |
|------|------|------|
| 内容创作与发布 | 10 | content-creation-publisher, article-illustrator |
| 视频创作 | 9 | video-creation-suite, video-recreation |
| 电商与营销 | 7 | ecommerce-full-pipeline |
| PPT与演示 | 6 | NanoBanana-PPT-Skills, ppt-generator |
| 语音与音频 | 3 | tts-voice-synthesis |
| 数字人与视频配音 | 5 | infinitetalk |
| 文档与分析 | 4 | paper-analysis-assistant, stock-analysis |
| 设计 | 4 | frontend-design, ai-drawio |
| 技能管理（系统内置）| 2 | find-skill, skill-creator |
| 文档处理（系统内置）| 4 | pptx, xlsx, pdf, docx |

## 注意事项

- "系统内置"技能（pptx, xlsx, pdf, docx, find-skill, skill-creator）为系统内置技能，无需从技能仓库安装
- 技能仓库路径为 `/home/lcxzero/repos/skill/`
- 技能数据文件：`data/skills.json`（官方）、`data/local_skills.json`（本地）
