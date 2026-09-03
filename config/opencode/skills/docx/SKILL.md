---
name: docx
description: Word文件处理技能 - 读取、解析和创建Word(.docx)文件。当用户需要读取文档内容、分析段落结构、提取表格数据、或者生成.docx文档时使用此技能。Use ONLY when the user asks to read, parse, extract content from, or create/edit Word .docx files.
---

# Word 文件处理

读取和创建 Word (.docx) 文件。

## 何时使用

- 读取/解析 .docx 文件内容
- 提取段落、标题、表格、图片
- 分析文档结构和样式
- 从 Markdown 或文本生成 .docx 文件
- 批量处理多个 Word 文档

## 不适用场景

- 仅讨论 Word 概念或格式时
- 处理 .doc（旧格式）文件时（建议先转换为 .docx）
- 需要渲染/预览 Word 时（使用截图等工具）

## 依赖

```bash
pip install python-docx>=0.8.11
```

## 读取 DOCX 文件

```python
from docx import Document

doc = Document("file.docx")

# 读取所有段落
for para in doc.paragraphs:
    if para.text.strip():
        print(f"[{para.style.name}] {para.text}")

# 读取所有表格
for table in doc.tables:
    for row in table.rows:
        cells = [cell.text for cell in row.cells]
        print(cells)
```

## 读取文档结构

```python
from docx import Document

doc = Document("file.docx")

# 统计信息
print(f"段落数: {len(doc.paragraphs)}")
print(f"表格数: {len(doc.tables)}")
print(f"节数: {len(doc.sections)}")

# 列出所有样式
for style in doc.styles:
    print(f"样式: {style.name}")
```

## 创建 DOCX 文件

```python
from docx import Document
from docx.shared import Pt, RGBColor, Inches
from docx.enum.text import WD_ALIGN_PARAGRAPH

doc = Document()

# 添加标题
heading = doc.add_heading("文档标题", level=1)
heading.alignment = WD_ALIGN_PARAGRAPH.CENTER

# 添加段落
para = doc.add_paragraph("这是一个段落。")
para.add_run(" 粗体文本").bold = True
para.add_run(" 红色文本").font.color.rgb = RGBColor(255, 0, 0)

# 添加表格
table = doc.add_table(rows=2, cols=3)
table.style = "Table Grid"
table.cell(0, 0).text = "表头1"
table.cell(0, 1).text = "表头2"
table.cell(0, 2).text = "表头3"

doc.save("output.docx")
```

## Markdown 转 DOCX

```python
from docx import Document
import re

def md_to_docx(md_file, docx_file):
    doc = Document()
    with open(md_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line.startswith('# '):
                doc.add_heading(line[2:], level=1)
            elif line.startswith('## '):
                doc.add_heading(line[3:], level=2)
            elif line.startswith('- '):
                doc.add_paragraph(line[2:], style='List Bullet')
            elif line:
                doc.add_paragraph(line)
    doc.save(docx_file)
```

## 完整工作流

1. 使用 python-docx 读取或创建 DOCX
2. 提取或生成文档内容
3. 保存结果到指定路径
