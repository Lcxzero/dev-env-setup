---
name: xlsx
description: Excel文件处理技能 - 读取、解析和创建Excel(.xlsx)文件。当用户需要读取表格数据、分析电子表格结构、执行数据计算、或者生成.xlsx报表时使用此技能。Use ONLY when the user asks to read, parse, extract data from, or create/edit Excel .xlsx files.
---

# Excel 文件处理

读取和创建 Excel (.xlsx) 文件。

## 何时使用

- 读取/解析 .xlsx 或 .xls 文件
- 提取工作表中的数据、公式、格式
- 数据分析、统计计算
- 生成 .xlsx 报表和表格
- 批量处理多个 Excel 文件

## 不适用场景

- 仅讨论 Excel 概念或公式时
- 需要在浏览器中查看 Excel 时

## 依赖

```bash
pip install openpyxl>=3.1.0
pip install pandas>=2.0.0
```

## 读取 XLSX 文件

```python
import openpyxl

wb = openpyxl.load_workbook("file.xlsx")
for sheet_name in wb.sheetnames:
    ws = wb[sheet_name]
    print(f"=== Sheet: {sheet_name} ===")
    for row in ws.iter_rows(values_only=True):
        print(row)
```

## 使用 Pandas 读取

```python
import pandas as pd

# 读取所有 sheet
xl = pd.ExcelFile("file.xlsx")
for sheet in xl.sheet_names:
    df = pd.read_excel("file.xlsx", sheet_name=sheet)
    print(f"=== {sheet} ===")
    print(df.head())
    print(df.describe())
```

## 创建 XLSX 文件

```python
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill

wb = Workbook()
ws = wb.active
ws.title = "Sheet1"

# 写入表头
headers = ["姓名", "部门", "薪资"]
for col, header in enumerate(headers, 1):
    cell = ws.cell(row=1, column=col, value=header)
    cell.font = Font(bold=True)
    cell.fill = PatternFill("solid", fgColor="4472C4")

# 写入数据
data = [
    ["张三", "技术部", 15000],
    ["李四", "产品部", 12000],
]
for row_idx, row_data in enumerate(data, 2):
    for col_idx, value in enumerate(row_data, 1):
        ws.cell(row=row_idx, column=col_idx, value=value)

wb.save("output.xlsx")
```

## 数据分析示例

```python
import pandas as pd

df = pd.read_excel("sales.xlsx")

# 统计
total = df["销售额"].sum()
average = df["销售额"].mean()

# 分组
by_dept = df.groupby("部门")["销售额"].sum()

# 筛选
high_sales = df[df["销售额"] > 10000]
```

## 完整工作流

1. 使用 openpyxl/pandas 读取或创建 XLSX
2. 执行数据处理和分析
3. 保存结果到指定路径
