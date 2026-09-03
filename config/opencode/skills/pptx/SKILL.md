---
name: pptx
description: PPT文件处理技能 - 读取、解析和创建PowerPoint(.pptx)文件。当用户需要读取PPT内容、提取文本、分析幻灯片结构、或者从JSON数据生成.pptx文件时使用此技能。Use ONLY when the user asks to read, parse, extract text from, or create/edit PowerPoint .pptx files.
---

# PPT 文件处理

读取和创建 PowerPoint (.pptx) 文件。

## 何时使用

- 读取/解析 .pptx 文件内容
- 提取幻灯片中的文本、标题、备注
- 分析幻灯片结构和布局
- 从 JSON 数据生成 .pptx 文件
- 批量处理多个 PPT 文件

## 不适用场景

- 仅讨论 PPT 概念或理论时
- 需要渲染/预览 PPT 时（此类请求通过截图等工具处理）
- 编辑现有 PPT 的视觉样式（需手动使用 python-pptx）

## 依赖

```
pip install python-pptx>=1.0.2
pip install pillow>=9.0.0
```

## 读取 PPTX 文件

```python
from pptx import Presentation

prs = Presentation("file.pptx")
for i, slide in enumerate(prs.slides):
    print(f"--- Slide {i+1} ---")
    for shape in slide.shapes:
        if shape.has_text_frame:
            for para in shape.text_frame.paragraphs:
                print(para.text)
```

## 创建 PPTX 文件（JSON → PPTX）

```python
from pptx import Presentation
from pptx.util import Inches, Pt

prs = Presentation()
blank_layout = prs.slide_layouts[6]  # blank layout

# 添加幻灯片
slide = prs.slides.add_slide(blank_layout)
txBox = slide.shapes.add_textbox(Inches(1), Inches(1), Inches(8), Inches(1))
tf = txBox.text_frame
tf.text = "标题文本"
p = tf.paragraphs[0]
p.font.size = Pt(44)
p.font.bold = True

prs.save("output.pptx")
```

## 完整工作流

1. 使用 `python-pptx` 读取/解析或创建 PPTX
2. 提取或生成结构化内容
3. 保存结果到指定路径
