---
name: pdf
description: PDF文件处理技能 - 读取、解析和处理PDF文件。当用户需要提取PDF文本、分析表单字段、识别表格、进行OCR、或处理PDF表单时使用此技能。Use ONLY when the user asks to read, parse, extract text from, fill forms in, or process PDF files.
---

# PDF 文件处理

读取和处理 PDF 文件。

## 何时使用

- 读取/解析 PDF 文本内容
- 提取 PDF 表单字段和数据
- 分析 PDF 表格结构
- OCR 识别扫描版 PDF
- 填写 PDF 表单
- 批量处理 PDF 文件

## 不适用场景

- 仅讨论 PDF 概念或格式时
- 需要渲染/预览 PDF 时（使用截图等工具）
- 创建/生成新的 PDF（使用 reportlab）

## 依赖

```bash
pip install pdfplumber>=0.10.0
pip install pypdf>=3.0.0
pip install pdf2image>=1.16.0
pip install Pillow>=10.0.0
# OCR（可选）
pip install pdfminer.six>=20221105
```

## 提取 PDF 文本

```python
import pdfplumber

with pdfplumber.open("file.pdf") as pdf:
    for i, page in enumerate(pdf.pages):
        text = page.extract_text()
        print(f"--- Page {i+1} ---")
        print(text)
```

## 提取 PDF 表格

```python
import pdfplumber

with pdfplumber.open("file.pdf") as pdf:
    for page in pdf.pages:
        tables = page.extract_tables()
        for table in tables:
            for row in table:
                print(row)
```

## 分析 PDF 表单

```python
from pypdf import PdfReader

reader = PdfReader("form.pdf")
if "/AcroForm" in reader.trailer["/Root"]:
    fields = reader.get_fields()
    for name, field in fields.items():
        print(f"{name}: {field.get('/V', '')}")
```

## OCR 扫描版 PDF

```python
from pdf2image import convert_from_path
import pytesseract

pages = convert_from_path("scanned.pdf")
for i, page in enumerate(pages):
    text = pytesseract.image_to_string(page, lang="chi_sim+eng")
    print(f"--- Page {i+1} ---")
    print(text)
```

## 完整工作流

1. 使用 pdfplumber/pypdf 读取 PDF
2. 提取文本、表格或表单数据
3. （可选）使用 OCR 处理扫描版
4. 保存或返回结构化结果
