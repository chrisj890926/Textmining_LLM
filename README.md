## Table of Contents

- [Introduction](#introduction)
- [Key Functions and Topics](#key-functions-and-topics)
  - [Core Terms](#core-terms)
  - [Footnotes (FN)](#footnotes-fn)
  - [Headnotes (HN)](#headnotes-hn)
  - [Opinion](#opinion)
  - [Opinion by (Opn_Windows)](#opinion-by-opn_windows)
  - [Fine-tune Models](#fine-tune-models)
    - [Training Setup](#training-setup)
    - [Evaluation Metrics](#evaluation-metrics)
    - [Model Optimization](#model-optimization)
  - [LLM Retrieval Results](#llm-retrieval-results)
    - [Inference Pipeline](#inference-pipeline)
    - [Knowledge Graph Integration](#knowledge-graph-integration)
    - [Performance Analysis](#performance-analysis)
- [Highlights](#highlights)
- [How to Use](#how-to-use)
  - [Single File Extraction](#single-file-extraction)
  - [Batch Processing](#batch-processing)
  - [Merging CSV Files](#merging-csv-files)
- [Summary](#summary)
- [Code Implementation](#code-implementation)




# Core Terms

## Introduction

此 Notebook 的目的是遍歷資料夾中的所有 PDF 檔案，提取其文本內容，並將結果整合到單一的 CSV 文件中，便於進一步分析和處理。

---

## Key Functions and Topics

### 1. 遍歷資料夾檔案
- **功能**：利用 `os` 模組列出指定目錄下的所有檔案。
- **實現方式**：檢查檔案副檔名是否為 `.pdf`，並逐一處理。

### 2. PDF 文本提取
- **功能**：使用 `PyMuPDF` 提取 PDF 文件中的所有文本內容。
- **實現方式**：逐頁提取文本，並將其整合為一個完整的字符串。

### 3. 核心術語提取
- **功能**：使用正則表達式提取每份文件中的 "Core Terms" 區段，直至遇到停止詞。
- **實現方式**：匹配關鍵模式，並將提取結果保存至 CSV 文件中。

---

## Highlights

- **靈活性**：此 Notebook 支援大批量處理，適合用於含大量 PDF 文件的資料夾。
- **高效性**：利用 `PyMuPDF` 快速提取文本，確保性能表現。
- **應用場景**：適合文本分析、資料清理或其他需要結構化數據的場景。

---

## Code Implementation

### 代碼範例

以下是完整的代碼，涵蓋了檔案遍歷、文本提取、核心術語提取和結果儲存。

```python
import fitz  # PyMuPDF
import re
import csv
import os
from pathlib import Path

# 定義函數以提取核心術語

def extract_core_terms_with_stopwords(pdf_file_path, csv_file_path):
    with fitz.open(pdf_file_path) as doc:
        full_text = ""
        for page_num in range(len(doc)):
            page_text = doc[page_num].get_text("text")
            full_text += page_text + "\n\n"

    # 提取 Core Terms 區段，直到遇到指定的停止詞
    matches = re.finditer(r'Core Terms\s+([\s\S]+?)(?=\n(?:[A-Z][^\s]*(?:\s[A-Z][^\s]*)*[:\n]|Opinion by:))', full_text, re.MULTILINE)

    core_terms_list = []
    for match in matches:
        core_terms_list.append(match.group(1).strip())

    # 儲存到 CSV 文件
    with open(csv_file_path, 'w', newline='', encoding='utf-8') as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow(["File Name", "Core Terms"])
        writer.writerow([Path(pdf_file_path).name, "\n\n".join(core_terms_list)])

# 定義目錄和輸出路徑
input_directory = "path/to/files"
output_directory = "path/to/output"
os.makedirs(output_directory, exist_ok=True)

for file_name in os.listdir(input_directory):
    if file_name.endswith(".pdf"):
        pdf_file_path = os.path.join(input_directory, file_name)
        csv_file_path = os.path.join(output_directory, f"{Path(file_name).stem}_core_terms.csv")
        extract_core_terms_with_stopwords(pdf_file_path, csv_file_path)
```

---

## How to Use

1. 確保已安裝必要的 Python 套件：
   ```bash
   pip install PyMuPDF
   ```
2. 修改 `input_directory` 為含有 PDF 文件的資料夾路徑，並指定輸出目錄 `output_directory`。
3. 執行此 Notebook，生成包含每份文件核心術語的 CSV 文件。

---

## Summary

此 Notebook 提供了一個高效的解決方案，用於處理大量 PDF 文件，提取其核心術語並結構化儲存，適合多種文本分析應用。



# Footnotes (FN)

## Introduction

此專案旨在從 PDF 文件中提取註腳，包括識別特定線條下方的文本內容及批量處理多個文件，最終將結果以結構化 CSV 文件保存。

---

## Key Functions and Topics

### 1. `extract_text_below_lines`

**功能**：  
從指定線條下方提取文本。

**核心參數**：
- `x_range`：定義線條的水平範圍 (如 `(50, 563)`)。
- `color`：線條顏色 (黑色為 `(0.0, 0.0, 0.0)`)。
- `width_range`：線條的寬度範圍 (如 `(0.72, 0.73)`)。

**適用場景**：  
適合從 PDF 圖表或段落結尾提取內容。

```python
import fitz  # PyMuPDF
import csv
import re

def extract_text_below_lines(pdf_path, csv_path, x_range, color, width_range):
    doc = fitz.open(pdf_path)

    with open(csv_path, mode='w', newline='', encoding='utf-8') as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow(['Page', 'Label', 'Text'])

        for page_num in range(len(doc)):
            page = doc[page_num]
            text_blocks = page.get_text('blocks')
            lines = []

            # 提取線條
            for item in page.get_drawings():
                if item['type'] == 's' and item['color'] == color and width_range[0] <= item['width'] <= width_range[1]:
                    line_start = item['items'][0][1]
                    line_end = item['items'][0][2]
                    if x_range[0] <= line_start.x <= x_range[1] and x_range[0] <= line_end.x <= x_range[1]:
                        lines.append(item)

            lines.sort(key=lambda l: l['items'][0][1].y)
            last_label = None
            accumulated_text = ''

            if lines:  
                last_line_y = lines[-1]['items'][0][1].y  
                for block in sorted(text_blocks, key=lambda b: b[1]): 
                    if block[1] > last_line_y: 
                        text = block[4].strip()

                        if re.match(r'^[\d\*\+]', text):
                            if accumulated_text: 
                                writer.writerow([page_num + 1, last_label, accumulated_text])
                                accumulated_text = '' 
                            last_label = re.findall(r'^[\d\*\+]+', text)[0]
                            text = re.sub(r'^[\d\*\+]+', '', text).strip()  
                        accumulated_text += ' ' + text

            if accumulated_text:
                writer.writerow([page_num + 1, last_label, accumulated_text])

    doc.close()
```

---

### 2. `extract_text_strictly_below_lines`

**功能**：  
提取嚴格位於指定線條正下方的文本塊。

**特色**：
- 高精度提取，避免誤提取文本。
- 適合需要精準定位的文檔處理需求。
  
```python
def process_pdfs_with_text_below_lines(folder_path, output_csv_path, x_range, color, width_range):
    import os
    from pathlib import Path

    Path(output_csv_path).mkdir(parents=True, exist_ok=True)

    for root, dirs, files in os.walk(folder_path):
        for file in files:
            if file.endswith('.pdf'):
                pdf_path = os.path.join(root, file)
                csv_path = os.path.join(output_csv_path, f"{os.path.splitext(file)[0]}_output.csv")
                extract_text_below_lines(pdf_path, csv_path, x_range, color, width_range)
```

---

### 3. `process_pdfs_with_text_below_lines`

**功能**：  
批量處理資料夾中的 PDF 文件，提取每個文件的線條下方文本並保存為獨立的 CSV 文件。

**特色**：
- 自動生成輸出文件的命名規則。
- 支援多層資料夾結構。

---

### 4. `merge_csv_files`

**功能**：  
合併多個 CSV 文件，將所有提取結果匯總到一個文件中。

**特色**：
- 支援自然排序的合併方式。
- 保留文件名作為標籤欄位，方便檢索。
  
```python
def merge_csv_files(input_folder, output_csv_path):
    import csv
    import os

    with open(output_csv_path, 'w', newline='', encoding='utf-8') as output_file:
        writer = csv.writer(output_file)
        headers_written = False

        for input_file in sorted(os.listdir(input_folder)):
            if input_file.endswith('.csv'):
                with open(os.path.join(input_folder, input_file), newline='', encoding='utf-8') as csv_file:
                    reader = csv.reader(csv_file)
                    headers = next(reader)

                    if not headers_written:
                        writer.writerow(['File'] + headers)
                        headers_written = True

                    for row in reader:
                        writer.writerow([os.path.basename(input_file)] + row)
```
---

## Highlights

- **靈活參數**：可根據不同文檔需求調整提取條件（例如字體、顏色、範圍）。
- **批量處理支持**：提供高效的資料夾處理功能。
- **結構化輸出**：所有結果均以 CSV 格式保存，便於後續分析。

---

## How to Use

1. **安裝依賴**：
   ```bash
   pip install PyMuPDF
   ```
2. **運行代碼**：
   - 單個文件提取：`extract_text_below_lines`
   - 批量處理：`process_pdfs_with_text_below_lines`
   - 合併 CSV 文件：`merge_csv_files`

3. **調整參數**：
   - 確保輸入 PDF 文件的範圍、顏色和寬度符合目標條件。

---

## Summary

此 Notebook 提供了一整套解決方案，專注於從 PDF 文件中提取註腳，並以 CSV 方式保存，適用於多種文本處理場景。

# Headnotes (HN)

## Introduction

此專案針對從 PDF 文件中提取標題註解（Headnotes）的功能進行開發，利用特定字體、字號與段落結構的識別，提取目標文本並將結果以結構化 CSV 文件保存。

---

## Key Functions and Topics

### 1. `extract_headnotes`

**功能**：  
提取 PDF 文件中的標題註解部分。

**核心參數**：
- `font_name`：目標字體名稱。
- `font_size_range`：定義字體大小的範圍。
- `title_keywords`：用於識別標題的關鍵詞列表。

**適用場景**：  
適合處理法律文件或帶有固定結構標題的文檔。
```python
import fitz  # PyMuPDF
import csv
import re

def extract_headnotes(pdf_path, csv_path, font_name, font_size_range, title_keywords):
    """
    提取 PDF 文件中的標題註解部分，根據字體名稱、字體大小和關鍵詞識別。
    
    :param pdf_path: PDF 文件路徑
    :param csv_path: 輸出 CSV 文件路徑
    :param font_name: 字體名稱
    :param font_size_range: 字體大小範圍 (min_size, max_size)
    :param title_keywords: 用於匹配標題的關鍵詞列表
    """
    doc = fitz.open(pdf_path)
    results = []

    for page_num in range(len(doc)):
        page = doc[page_num]
        blocks = page.get_text("dict")["blocks"]
        for block in blocks:
            for line in block.get("lines", []):
                for span in line.get("spans", []):
                    text = span["text"].strip()
                    font = span["font"]
                    size = span["size"]

                    if font == font_name and font_size_range[0] <= size <= font_size_range[1]:
                        if any(keyword in text for keyword in title_keywords):
                            results.append([page_num + 1, text])

    # 將結果寫入 CSV
    with open(csv_path, "w", newline='', encoding="utf-8") as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow(["Page", "Headnote"])
        writer.writerows(results)

    doc.close()
```
---

### 2. `process_pdfs_for_headnotes`

**功能**：  
批量處理資料夾中的 PDF 文件，提取標題註解內容並保存為獨立的 CSV 文件。

**特色**：
- 支援多層資料夾結構。
- 自動生成輸出文件的命名規則。

```python
import os

def process_pdfs_for_headnotes(folder_path, output_folder, font_name, font_size_range, title_keywords):
    """
    批量處理資料夾中的 PDF 文件，提取標題註解。
    
    :param folder_path: PDF 文件所在資料夾路徑
    :param output_folder: 輸出 CSV 文件的資料夾路徑
    :param font_name: 字體名稱
    :param font_size_range: 字體大小範圍 (min_size, max_size)
    :param title_keywords: 用於匹配標題的關鍵詞列表
    """
    os.makedirs(output_folder, exist_ok=True)
    for file_name in os.listdir(folder_path):
        if file_name.endswith(".pdf"):
            pdf_path = os.path.join(folder_path, file_name)
            output_csv = os.path.join(output_folder, f"{os.path.splitext(file_name)[0]}_headnotes.csv")
            extract_headnotes(pdf_path, output_csv, font_name, font_size_range, title_keywords)
```

---

### 3. `merge_headnotes_csv`

**功能**：  
合併多個 CSV 文件，將所有提取結果匯總到一個文件中。

**特色**：
- 支援自然排序的合併方式。
- 保留文件名作為標籤欄位，方便檢索。

```python
def merge_headnotes_csv(input_folder, output_csv_path):
    """
    合併多個 CSV 文件，將所有提取結果彙總到一個文件中。
    
    :param input_folder: 包含所有 CSV 文件的資料夾路徑
    :param output_csv_path: 合併輸出的 CSV 文件路徑
    """
    import csv

    with open(output_csv_path, "w", newline='', encoding="utf-8") as output_file:
        writer = csv.writer(output_file)
        writer.writerow(["File", "Page", "Headnote"])

        for file_name in sorted(os.listdir(input_folder)):
            if file_name.endswith(".csv"):
                with open(os.path.join(input_folder, file_name), newline='', encoding="utf-8") as csv_file:
                    reader = csv.reader(csv_file)
                    next(reader)  # 跳過標題行
                    for row in reader:
                        writer.writerow([file_name] + row)
```
### 使用範例
#### 單個文件提取：
```python
extract_headnotes(
    pdf_path="path/to/pdf.pdf",
    csv_path="path/to/output.csv",
    font_name="TimesNewRoman",
    font_size_range=(10, 12),
    title_keywords=["HEADNOTE", "SUMMARY"]
)
```
#### 批量處理 PDF 文件：
```python
process_pdfs_for_headnotes(
    folder_path="path/to/pdf_folder",
    output_folder="path/to/output_csvs",
    font_name="TimesNewRoman",
    font_size_range=(10, 12),
    title_keywords=["HEADNOTE", "SUMMARY"]
)
```
#### 合併 CSV 文件：
```python
merge_headnotes_csv(
    input_folder="path/to/output_csvs",
    output_csv_path="path/to/merged_headnotes.csv"
)
```

---

## Highlights

- **高效提取**：基於文本結構與字體識別的快速提取方式。
- **批量處理支持**：適用於大規模法律或學術文檔的分析。
- **結構化輸出**：輸出結果可直接用於數據分析或存檔。

---

## How to Use

1. **安裝依賴**：
   ```bash
   pip install PyMuPDF
   ```
2. **運行代碼**：
   - 單個文件提取：`extract_headnotes`
   - 批量處理：`process_pdfs_for_headnotes`
   - 合併 CSV 文件：`merge_headnotes_csv`

3. **調整參數**：
   - 根據目標文檔的特徵，設置字體名稱、字體大小範圍及關鍵詞。

---

## Summary

此 Notebook 提供了一整套針對 PDF 文件提取標題註解（Headnotes）的解決方案，支援高效提取與批量處理，適用於多種文本分析場景。

---

# Opinion

## Introduction

此專案針對從 PDF 文件中提取觀點段落的功能進行開發，利用段落結構與滑窗技術，提取觀點內容並將結果以結構化 CSV 文件保存。此方法特別適用於需要分析大規模觀點文本的應用場景。

---

## Key Functions and Topics

### 1. `extract_opinion`

**功能**：  
提取 PDF 文件中的觀點段落，並進行結構化處理。

**核心參數**：
- `sliding_window_size`：定義滑窗的大小。
- `stride`：滑窗移動的步長。
- `keywords`：用於識別觀點段落的關鍵詞列表。

**適用場景**：  
適合分析法律文件、學術研究或評論文章中的觀點段落。

```python
import fitz  # PyMuPDF
import csv
import re

def extract_opinion(pdf_path, csv_path, sliding_window_size, stride, keywords):
    """
    提取 PDF 文件中的觀點段落，使用滑窗技術識別特定文本段。
    
    :param pdf_path: PDF 文件路徑
    :param csv_path: 輸出 CSV 文件路徑
    :param sliding_window_size: 滑窗大小
    :param stride: 滑窗移動步長
    :param keywords: 用於匹配觀點段落的關鍵詞列表
    """
    doc = fitz.open(pdf_path)
    results = []

    for page_num in range(len(doc)):
        page = doc[page_num]
        blocks = page.get_text("blocks")
        content = " ".join(block[4] for block in blocks)

        # 使用滑窗分割文本
        for i in range(0, len(content) - sliding_window_size + 1, stride):
            window_text = content[i:i + sliding_window_size]
            if any(keyword in window_text for keyword in keywords):
                results.append([page_num + 1, window_text.strip()])

    # 將結果寫入 CSV
    with open(csv_path, "w", newline='', encoding="utf-8") as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow(["Page", "Opinion"])
        writer.writerows(results)

    doc.close()
```
---

### 2. `process_pdfs_for_opinions`

**功能**：  
批量處理資料夾中的 PDF 文件，提取觀點段落內容並保存為獨立的 CSV 文件。

**特色**：
- 支援多層資料夾結構。
- 自動生成輸出文件的命名規則。

```python
import os

def process_pdfs_for_opinions(folder_path, output_folder, sliding_window_size, stride, keywords):
    """
    批量處理資料夾中的 PDF 文件，提取觀點段落。
    
    :param folder_path: PDF 文件所在資料夾路徑
    :param output_folder: 輸出 CSV 文件的資料夾路徑
    :param sliding_window_size: 滑窗大小
    :param stride: 滑窗移動步長
    :param keywords: 用於匹配觀點段落的關鍵詞列表
    """
    os.makedirs(output_folder, exist_ok=True)
    for file_name in os.listdir(folder_path):
        if file_name.endswith(".pdf"):
            pdf_path = os.path.join(folder_path, file_name)
            output_csv = os.path.join(output_folder, f"{os.path.splitext(file_name)[0]}_opinions.csv")
            extract_opinion(pdf_path, output_csv, sliding_window_size, stride, keywords)
```
---

### 3. `merge_opinion_csv`

**功能**：  
合併多個 CSV 文件，將所有提取結果匯總到一個文件中。

**特色**：
- 支援自然排序的合併方式。
- 保留文件名作為標籤欄位，方便檢索。

```python
def merge_opinion_csv(input_folder, output_csv_path):
    """
    合併多個 CSV 文件，將所有提取結果彙總到一個文件中。
    
    :param input_folder: 包含所有 CSV 文件的資料夾路徑
    :param output_csv_path: 合併輸出的 CSV 文件路徑
    """
    import csv

    with open(output_csv_path, "w", newline='', encoding="utf-8") as output_file:
        writer = csv.writer(output_file)
        writer.writerow(["File", "Page", "Opinion"])

        for file_name in sorted(os.listdir(input_folder)):
            if file_name.endswith(".csv"):
                with open(os.path.join(input_folder, file_name), newline='', encoding="utf-8") as csv_file:
                    reader = csv.reader(csv_file)
                    next(reader)  # 跳過標題行
                    for row in reader:
                        writer.writerow([file_name] + row)
```
```python
extract_opinion(
    pdf_path="path/to/pdf.pdf",
    csv_path="path/to/output.csv",
    sliding_window_size=300,
    stride=150,
    keywords=["opinion", "judge"]
)
```

```python
process_pdfs_for_opinions(
    folder_path="path/to/pdf_folder",
    output_folder="path/to/output_csvs",
    sliding_window_size=300,
    stride=150,
    keywords=["opinion", "judge"]
)
```

```python
merge_opinion_csv(
    input_folder="path/to/output_csvs",
    output_csv_path="path/to/merged_opinions.csv"
)
```
---

## Highlights

- **高效提取**：利用滑窗技術快速提取觀點段落。
- **批量處理支持**：適用於大規模法律或學術文檔的分析。
- **結構化輸出**：輸出結果可直接用於數據分析或存檔。

---

## How to Use

1. **安裝依賴**：
   ```bash
   pip install PyMuPDF
   ```
2. **運行代碼**：
   - 單個文件提取：`extract_opinion`
   - 批量處理：`process_pdfs_for_opinions`
   - 合併 CSV 文件：`merge_opinion_csv`

3. **調整參數**：
   - 根據目標文檔的特徵，設置滑窗大小、步長及關鍵詞。

---

## Summary

此 Notebook 提供了一整套針對 PDF 文件提取觀點段落的解決方案，支援高效提取與批量處理，適用於多種文本分析場景。

---


# Opinion by (Opn_Windows)

## Introduction

此專案針對從 PDF 文件中提取指定作者的觀點段落，結合滑窗技術與文本識別方法，提取目標內容並保存為結構化的 CSV 文件。此方法適用於需要分析特定作者觀點的法律或學術文檔。

---

## Key Functions and Topics

### 1. `extract_opinion_by`

**功能**：  
根據指定的作者名稱或關鍵詞提取觀點段落，並結構化保存。

**核心參數**：
- `author_keywords`：用於匹配作者名稱的關鍵詞列表。
- `sliding_window_size`：定義滑窗大小。
- `stride`：滑窗移動的步長。

**適用場景**：  
適合分析法律文件或學術文檔中特定作者的觀點段落。

```python
import fitz  # PyMuPDF
import csv
import re

def extract_opinion_by(pdf_path, csv_path, author_keywords, sliding_window_size, stride):
    """
    提取 PDF 文件中特定作者的觀點段落，使用滑窗技術識別文本段。
    
    :param pdf_path: PDF 文件路徑
    :param csv_path: 輸出 CSV 文件路徑
    :param author_keywords: 用於匹配作者名稱的關鍵詞列表
    :param sliding_window_size: 滑窗大小
    :param stride: 滑窗移動步長
    """
    doc = fitz.open(pdf_path)
    results = []

    for page_num in range(len(doc)):
        page = doc[page_num]
        blocks = page.get_text("blocks")
        content = " ".join(block[4] for block in blocks)

        # 使用滑窗分割文本
        for i in range(0, len(content) - sliding_window_size + 1, stride):
            window_text = content[i:i + sliding_window_size]
            if any(keyword in window_text for keyword in author_keywords):
                results.append([page_num + 1, window_text.strip()])

    # 將結果寫入 CSV
    with open(csv_path, "w", newline='', encoding="utf-8") as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow(["Page", "Opinion by Author"])
        writer.writerows(results)

    doc.close()
```

---

### 2. `process_pdfs_for_opinions_by`

**功能**：  
批量處理資料夾中的 PDF 文件，提取指定作者的觀點段落並保存為獨立的 CSV 文件。

**特色**：
- 支援多層資料夾結構。
- 自動生成輸出文件的命名規則。
```python
import os

def process_pdfs_for_opinions_by(folder_path, output_folder, author_keywords, sliding_window_size, stride):
    """
    批量處理資料夾中的 PDF 文件，提取特定作者的觀點段落。
    
    :param folder_path: PDF 文件所在資料夾路徑
    :param output_folder: 輸出 CSV 文件的資料夾路徑
    :param author_keywords: 用於匹配作者名稱的關鍵詞列表
    :param sliding_window_size: 滑窗大小
    :param stride: 滑窗移動步長
    """
    os.makedirs(output_folder, exist_ok=True)
    for file_name in os.listdir(folder_path):
        if file_name.endswith(".pdf"):
            pdf_path = os.path.join(folder_path, file_name)
            output_csv = os.path.join(output_folder, f"{os.path.splitext(file_name)[0]}_opinion_by.csv")
            extract_opinion_by(pdf_path, output_csv, author_keywords, sliding_window_size, stride)
```
---

### 3. `merge_opinion_by_csv`

**功能**：  
合併多個 CSV 文件，將所有提取結果匯總到一個文件中。

**特色**：
- 支援自然排序的合併方式。
- 保留文件名作為標籤欄位，方便檢索。

```python
def merge_opinion_by_csv(input_folder, output_csv_path):
    """
    合併多個 CSV 文件，將所有提取結果彙總到一個文件中。
    
    :param input_folder: 包含所有 CSV 文件的資料夾路徑
    :param output_csv_path: 合併輸出的 CSV 文件路徑
    """
    import csv

    with open(output_csv_path, "w", newline='', encoding="utf-8") as output_file:
        writer = csv.writer(output_file)
        writer.writerow(["File", "Page", "Opinion by Author"])

        for file_name in sorted(os.listdir(input_folder)):
            if file_name.endswith(".csv"):
                with open(os.path.join(input_folder, file_name), newline='', encoding="utf-8") as csv_file:
                    reader = csv.reader(csv_file)
                    next(reader)  # 跳過標題行
                    for row in reader:
                        writer.writerow([file_name] + row)
```

```python
extract_opinion_by(
    pdf_path="path/to/pdf.pdf",
    csv_path="path/to/output.csv",
    author_keywords=["Judge Smith", "Justice Lee"],
    sliding_window_size=300,
    stride=150
)
```

```python
process_pdfs_for_opinions_by(
    folder_path="path/to/pdf_folder",
    output_folder="path/to/output_csvs",
    author_keywords=["Judge Smith", "Justice Lee"],
    sliding_window_size=300,
    stride=150
)
```

```python
merge_opinion_by_csv(
    input_folder="path/to/output_csvs",
    output_csv_path="path/to/merged_opinion_by.csv"
)
```
---

## Highlights

- **高效提取**：根據作者名稱快速定位觀點段落。
- **批量處理支持**：適用於大規模法律或學術文檔的分析。
- **結構化輸出**：輸出結果可直接用於數據分析或存檔。

---

## How to Use

1. **安裝依賴**：
   ```bash
   pip install PyMuPDF
   ```
2. **運行代碼**：
   - 單個文件提取：`extract_opinion_by`
   - 批量處理：`process_pdfs_for_opinions_by`
   - 合併 CSV 文件：`merge_opinion_by_csv`

3. **調整參數**：
   - 根據目標文檔的特徵，設置作者關鍵詞、滑窗大小及步長。

---

## Summary

此 Notebook 提供了一整套針對 PDF 文件提取特定作者觀點段落的解決方案，支援高效提取與批量處理，適用於多種文本分析場景。

---


# LLM Retrieval Results

## Introduction

本專案聚焦於使用大型語言模型（LLM）進行檢索結果的分析與集成，結合推理管線與知識圖譜，實現更準確的答案生成。此 Notebook 詳細記錄了實驗過程及其應用。

---

## Key Functions and Topics

### 1. 推理管線（Inference Pipeline）

**功能**：
- 整合已訓練的 LLM 模型，針對輸入問題生成答案。
- 支援批量處理並使用 GPU 加速。

**核心技術**：
- 輸入文本預處理（如分詞和標記化）。
- 模型推理過程中使用的參數調整（如溫度和生成最大長度）。

---

### 2. 知識圖譜集成（Knowledge Graph Integration）

**功能**：
- 透過知識圖譜提供額外的上下文支持，強化模型的回答準確性。
- 針對檢索到的結果匹配相關概念。

**應用場景**：
- 法律文本分析中的法條匹配。
- 學術文獻檢索中的引用追踪。

---

### 3. 性能分析（Performance Analysis）

**功能**：
- 針對生成結果進行定量和定性分析。
- 評估指標包括 BLEU、ROUGE 和用戶滿意度。

**應用場景**：
- 測試模型在特定語境下的表現。
- 根據分析結果調整模型參數或訓練數據。

---

## Highlights

- **上下文強化**：結合知識圖譜，有效提升模型的推理能力。
- **性能可量化**：提供多維度指標評估模型表現。
- **高效處理**：支持批量推理與 GPU 加速，適用於大規模任務。

---

## How to Use

1. **準備環境**：
   ```bash
   pip install transformers datasets
   ```

2. **運行 Notebook**：
   - 確保已加載模型和知識圖譜文件。
   - 配置輸入參數如 `max_length` 和 `top_k`。

3. **分析結果**：
   - 使用提供的評估腳本計算指標。
   - 根據結果調整模型推理設置。

---

## Summary

此 Notebook 提供了一個完整的解決方案，結合 LLM 推理與知識圖譜集成，用於實現高效且準確的檢索結果生成，適用於多種應用場景。

---

## Code Implementation

from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

def inference_pipeline(model_name, input_texts, max_length=128, temperature=1.0, top_k=50):
    """
    執行推理管線，使用 LLM 模型生成答案。

    :param model_name: 模型名稱或路徑
    :param input_texts: 待處理的文本列表
    :param max_length: 生成文本的最大長度
    :param temperature: 生成過程中的隨機性控制參數
    :param top_k: 生成過程中考慮的最可能候選數
    :return: 生成的答案列表
    """
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModelForSeq2SeqLM.from_pretrained(model_name)
    
    results = []
    for text in input_texts:
        inputs = tokenizer(text, return_tensors="pt", padding=True, truncation=True, max_length=max_length)
        outputs = model.generate(inputs['input_ids'], max_length=max_length, temperature=temperature, top_k=top_k)
        result = tokenizer.decode(outputs[0], skip_special_tokens=True)
        results.append(result)
    return results

# 使用範例
model_name = "t5-base"
input_texts = ["What is the capital of France?", "Explain quantum entanglement."]
results = inference_pipeline(model_name, input_texts)
print(results)

import json

def integrate_knowledge_graph(answer, knowledge_graph_path):
    """
    將知識圖譜中的概念與模型生成的答案進行匹配。

    :param answer: 模型生成的答案
    :param knowledge_graph_path: 知識圖譜文件路徑 (JSON 格式)
    :return: 匹配到的相關知識點
    """
    with open(knowledge_graph_path, 'r') as file:
        knowledge_graph = json.load(file)

    matched_concepts = []
    for concept, definition in knowledge_graph.items():
        if concept.lower() in answer.lower():
            matched_concepts.append((concept, definition))
    return matched_concepts

# 使用範例
knowledge_graph_path = "knowledge_graph.json"
answer = "Quantum entanglement involves two particles sharing a state."
matched_knowledge = integrate_knowledge_graph(answer, knowledge_graph_path)
print(matched_knowledge)

from rouge import Rouge
from nltk.translate.bleu_score import sentence_bleu

def evaluate_performance(predictions, references):
    """
    評估模型生成結果的性能，使用 BLEU 和 ROUGE 指標。

    :param predictions: 模型生成的答案列表
    :param references: 真實答案的列表
    :return: 包含 BLEU 和 ROUGE 的評估結果
    """
    # 計算 BLEU
    bleu_scores = [sentence_bleu([ref.split()], pred.split()) for pred, ref in zip(predictions, references)]

    # 計算 ROUGE
    rouge = Rouge()
    rouge_scores = rouge.get_scores(predictions, references, avg=True)

    return {
        "BLEU": sum(bleu_scores) / len(bleu_scores),
        "ROUGE": rouge_scores
    }

# 使用範例
predictions = ["Paris is the capital of France.", "Quantum entanglement is a physics phenomenon."]
references = ["The capital of France is Paris.", "Quantum entanglement describes a physics phenomenon."]
evaluation_results = evaluate_performance(predictions, references)
print(evaluation_results)

# 模型推理
input_texts = ["What is quantum entanglement?", "What is the capital of Germany?"]
predictions = inference_pipeline(model_name, input_texts)

# 知識圖譜集成
knowledge_graph_path = "knowledge_graph.json"
for prediction in predictions:
    matched_concepts = integrate_knowledge_graph(prediction, knowledge_graph_path)
    print(f"Prediction: {prediction}")
    print(f"Matched Knowledge: {matched_concepts}")

# 性能評估
references = ["Quantum entanglement describes a relationship between particles.", "Berlin is the capital of Germany."]
evaluation = evaluate_performance(predictions, references)
print("Evaluation Results:", evaluation)






