---
name: skill-creator
description: 技能创建工具 - 创建新的AI Agent技能文件(SKILL.md)。当用户需要创建自定义技能、编写技能描述、定义技能触发条件、或按规范模板创建技能时使用此技能。Use ONLY when the user asks to create, write, or build a new AI Agent skill with SKILL.md.
---

# 技能创建工具

按规范创建新的 AI Agent 技能。

## 何时使用

- 创建新的自定义技能
- 编写技能的 SKILL.md 文件
- 定义技能的触发条件和描述
- 使用模板创建标准化技能

## 技能仓库位置

```
/home/lcxzero/repos/skill/skills/_template/
```

## SKILL.md 规范

每个技能必须包含以下部分：

### Frontmatter（必需）

```markdown
---
name: skill-name
description: 一句话描述技能功能和使用场景，包含触发关键词
---
```

- `name`：技能名称，小写字母+连字符，最多64字符
- `description`：描述技能做什么以及何时使用，包含触发关键词

### 正文结构

```markdown
# 技能名称

## 何时使用
- 具体触发条件1
- 具体触发条件2

## 不适用场景
- 不应触发的情况

## 前置准备
- 依赖安装
- 环境配置

## 操作步骤
1. 步骤一
2. 步骤二

## 注意事项
- 限制和约束
```

## 创建技能流程

### 步骤 1：确定技能信息

```
技能名称: {name}
技能描述: {description}
触发条件: {triggers}
```

### 步骤 2：创建目录结构

```bash
mkdir -p /home/lcxzero/repos/skill/skills/{skill-name}
```

### 步骤 3：编写 SKILL.md

按照上面的规范编写，包含：
- Frontmatter（name + description）
- 何时使用 / 不适用场景
- 操作步骤（代码示例）
- 注意事项

### 步骤 4：验证技能

```bash
cd /home/lcxzero/repos/skill
python tools/skill_validator.py validate skills/{skill-name}
```

## 快速模板

复制 `_template` 目录作为起点：

```bash
cp -r /home/lcxzero/repos/skill/skills/_template /home/lcxzero/repos/skill/skills/my-new-skill
# 编辑 SKILL.md 填充实际内容
```

## 示例：创建一个简单技能

```markdown
---
name: csv-processor
description: CSV文件处理技能 - 读取、分析和转换CSV文件。当用户需要处理CSV数据、统计分析、数据清洗、或格式转换时使用。
---

# CSV 文件处理

读取和分析 CSV 文件。

## 何时使用
- 读取/解析 CSV 文件
- 数据统计和分析
- CSV 格式转换
- 数据清洗

## 依赖
```bash
pip install pandas
```

## 读取 CSV
```python
import pandas as pd
df = pd.read_csv("data.csv")
print(df.head())
print(df.describe())
```
```
