## Table of Contents

- [Introduction](#introduction)
- [Key Functions and Topics](#key-functions-and-topics)
  - [Core Terms](#core-terms)
      - [Highlights](#highlights)
      - [How to Use](#how-to-use)
  - [Footnotes (FN)](#footnotes-fn)
      - [Highlights](#highlights)
      - [How to Use](#how-to-use)
  - [Headnotes (HN)](#headnotes-hn)
      - [Highlights](#highlights)
      - [How to Use](#how-to-use)
  - [Opinion](#opinion)
      - [Highlights](#highlights)
      - [How to Use](#how-to-use)
  - [Opinion by (Opn_Windows)](#opinion-by-opn_windows)
      - [Highlights](#highlights)
      - [How to Use](#how-to-use)
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
### 導入HuggingFace Model
```python
from transformers import BertTokenizer, BertForQuestionAnswering

# 加載預訓練的 BERT 模型和分詞器
model_name = "bert-large-uncased-whole-word-masking-finetuned-squad"
tokenizer = BertTokenizer.from_pretrained(model_name)
model = BertForQuestionAnswering.from_pretrained(model_name)
```

```
### 合併DataFrame
```python
import os
import pandas as pd

# 指定資料夾路徑
folder_path = r'C:\Users\User\Dropbox\textmining1\Data2_Opinion_low'  # 替換成您的資料夾路徑

# 遍歷資料夾中的所有 CSV 文件
csv_files = [f for f in os.listdir(folder_path) if f.endswith('_opinion.csv')]

# 用來儲存所有 CSV 的列表
dataframes = []

# 讀取每個 CSV 文件並加載到 DataFrame 中
for csv_file in csv_files:
    file_path = os.path.join(folder_path, csv_file)
    df = pd.read_csv(file_path)  # 讀取 CSV
    dataframes.append(df)  # 將 DataFrame 添加到列表中

# 如果需要，將所有 DataFrame 合併成一個大的 DataFrame
final_df = pd.concat(dataframes, ignore_index=True)


# 顯示合併後的 DataFrame
print(final_df)

```
### 導入必要的庫和設置
```python
# 1. Import necessary libraries
import os
import pandas as pd
from transformers import BertTokenizer
from sklearn.model_selection import train_test_split
from datasets import Dataset
from tqdm.notebook import tqdm  # 用於顯示進度條

# 2. Load tokenizer
tokenizer = BertTokenizer.from_pretrained('nlpaueb/legal-bert-base-uncased')
# 加載模型並將其移動到 GPU (如果有)
model = BertForQuestionAnswering.from_pretrained('nlpaueb/legal-bert-base-uncased')
model.to(torch.device("cuda" if torch.cuda.is_available() else "cpu"))

```
### 讀取所有 CSV 文件並合併
```python
# 3. Set folder path and read CSV files
folder_path = "file_path.csv"  # 替換成您的資料夾路徑

# Get all CSV files in the folder
csv_files = [f for f in os.listdir(folder_path) if f.endswith('_opinion.csv')]

# Initialize list to store dataframes
dataframes = []

# Read each CSV file and append it to the list
for csv_file in tqdm(csv_files, desc="Reading CSV files"):
    file_path = os.path.join(folder_path, csv_file)
    df = pd.read_csv(file_path)  # Read CSV
    dataframes.append(df)  # Add DataFrame to the list

# Merge all dataframes into one large dataframe
final_df = pd.concat(dataframes, ignore_index=True)

# Display merged dataframe
print(final_df.head())

```
### 裁剪文本並創建問答對
```python
# 4. Function to split text into chunks (max_length 512 tokens)
def split_text_into_chunks(text, max_length=256):
    # Tokenize the text, do not truncate yet
    tokens = tokenizer.encode(text, truncation=False)
    
    chunks = []
    
    # Split the tokens into chunks of size max_length
    while len(tokens) > max_length:
        chunk = tokens[:max_length]  # First chunk of max_length tokens
        chunks.append(chunk)         # Append the chunk to the list
        tokens = tokens[max_length:] # Remaining tokens to be processed
    
    # If there are leftover tokens, process them
    if len(tokens) > 0:
        chunks.append(tokens)
    
    # Ensure that each chunk is strictly max_length or less
    chunks = [chunk[:max_length] for chunk in chunks]  # Ensure no chunk exceeds max_length
    
    return chunks

```
```python
# 5. Create Q&A pairs and split the text
train_data = []
for _, row in tqdm(final_df.iterrows(), total=final_df.shape[0], desc="Processing text"):
    case_index = row['Case Index']
    paragraph = row['Paragraph']
    
    # Split paragraph into chunks
    paragraph_chunks = split_text_into_chunks(paragraph)
    
    for chunk in paragraph_chunks:
        # Decode tokens back to text
        context = tokenizer.decode(chunk, skip_special_tokens=True)
        
        # Create question and answer pair
        question = f"What is the judge's opinion regarding entry barriers in case {case_index}?"
        train_data.append({"question": question, "context": context, "answer": context})
        
        # If prosecutor's argument is involved
        question_prosecutor = f"What is the prosecutor's argument regarding entry barriers in case {case_index}?"
        train_data.append({"question": question_prosecutor, "context": context, "answer": context})

```
### 檢查裁切文本長度
#### 檢查段落的長度
```python
# 假設您已經有一個處理過的 DataFrame `final_df` 和 `tokenizer`
def check_token_lengths(final_df, tokenizer, max_length=512):
    for _, row in df.iterrows():
        paragraph = row['Paragraph']
        
        # Tokenize the paragraph to check the length
        inputs = tokenizer(paragraph, truncation=True, padding='max_length', max_length=max_length, return_tensors='pt')
        
        # Print the length of tokens after tokenization
        print(f"Original length: {len(paragraph)} characters")
        print(f"Tokenized length: {len(inputs['input_ids'][0])} tokens")
        print(f"Tokenized text (first 50 tokens): {inputs['input_ids'][0][:50]}")  # Display first 50 tokens
        
# 執行檢查
check_token_lengths(final_df, tokenizer)

```

#### 確保文本正確裁剪
```python
def split_text_into_chunks(text, max_length=256):
    tokens = tokenizer.encode(text, truncation=False)  # 不進行裁剪，先取得所有tokens
    print(f"Total tokens before splitting: {len(tokens)}")
    chunks = []
    
    # If the text exceeds max_length, split it
    while len(tokens) > max_length:
        chunk = tokens[:max_length]
        chunks.append(chunk)
        tokens = tokens[max_length:]
    
    # Add any remaining tokens
    if len(tokens) > 0:
        chunks.append(tokens)
    
    print(f"Number of chunks after splitting: {len(chunks)}")
    print(f"Tokens in the first chunk: {len(chunks[0])}")
    return chunks

# Example of splitting a long paragraph
example_paragraph = final_df.iloc[0]['Paragraph']  # Example paragraph from the dataset
split_chunks = split_text_into_chunks(example_paragraph)

```

#### 驗證裁剪後的文本內容
```python
def check_split_chunks(chunks, tokenizer):
    for i, chunk in enumerate(chunks):
        text = tokenizer.decode(chunk, skip_special_tokens=True)  # Decode the chunk back to text
        print(f"Chunk {i+1}: {text[:100]}...")  # Display first 100 characters of each chunk

# Check chunks for a specific paragraph
check_split_chunks(split_chunks, tokenizer)

```

### 分割訓練集和測試集
```python
# 6. Split the data into train and validation sets
train_data, val_data = train_test_split(train_data, test_size=0.2, random_state=42)

# Convert to Hugging Face Dataset format
train_dataset = Dataset.from_dict({
    "question": [entry["question"] for entry in train_data],
    "context": [entry["context"] for entry in train_data],
    "answer": [entry["answer"] for entry in train_data],
})

val_dataset = Dataset.from_dict({
    "question": [entry["question"] for entry in val_data],
    "context": [entry["context"] for entry in val_data],
    "answer": [entry["answer"] for entry in val_data],
})

```
```python
from transformers import BertTokenizer  # 確保導入BertTokenizer
import torch
from datasets import Dataset

# Initialize tokenizer
tokenizer = BertTokenizer.from_pretrained('nlpaueb/legal-bert-base-uncased')

# Function to split text into chunks (max_length 512 tokens)
def split_text_into_chunks(text, max_length=256):
    tokens = tokenizer.encode(text, truncation=False)  # Don't truncate yet, just get all tokens
    chunks = []
    
    # Split the tokens into chunks of size max_length
    while len(tokens) > max_length:
        chunk = tokens[:max_length]
        chunks.append(chunk)
        tokens = tokens[max_length:]
    
    # Add any remaining tokens
    if len(tokens) > 0:
        chunks.append(tokens)
    
    print(f"Total tokens before splitting: {len(tokens)}")
    print(f"Number of chunks after splitting: {len(chunks)}")
    print(f"Tokens in the first chunk: {len(chunks[0])}")
    return chunks

# Example usage: Process a specific paragraph from the dataframe
example_paragraph = "This is an example paragraph. It will be tokenized and split into chunks."
split_chunks = split_text_into_chunks(example_paragraph)
```

### 進行tokenization -> 生成 start/end positions -> 將數據移到GPU
```python
def tokenize_and_find_answers(examples, tokenizer):
    # Tokenizer 需要傳遞的資料
    questions = examples['question']
    contexts = examples['context']
    
    # 用 tokenizer 處理問題和上下文
    inputs = tokenizer(questions, contexts, truncation=True, padding='max_length', max_length=512, return_tensors='pt')

    # 處理每個上下文中的範例
    start_positions = []
    end_positions = []
    
    for i, context in enumerate(examples['context']):
        answer = examples['answer'][i]
        
        # 找到答案在上下文中的位置
        start_position = context.find(answer)
        end_position = start_position + len(answer)

        # 調整位置來符合 tokenized 輸入
        start_token_pos = len(tokenizer.encode(context[:start_position], truncation=True, padding='max_length', max_length=512)) - 1
        end_token_pos = len(tokenizer.encode(context[:end_position], truncation=True, padding='max_length', max_length=512)) - 1

        start_positions.append(start_token_pos)
        end_positions.append(end_token_pos)

    # 使用 torch.tensor 將位置轉為 PyTorch 張量
    inputs['start_positions'] = torch.tensor(start_positions)
    inputs['end_positions'] = torch.tensor(end_positions)

    return inputs

```
```python
from transformers import BertTokenizer
import torch

# Load tokenizer once
tokenizer = BertTokenizer.from_pretrained('nlpaueb/legal-bert-base-uncased')

# Use device (GPU if available)
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

def tokenize_and_find_answers(examples, tokenizer):
    # Extract questions and contexts from the batch (which are lists)
    questions = examples['question']
    contexts = examples['context']
    
    # Tokenize the batch of questions and contexts
    inputs = tokenizer(questions, contexts, truncation=True, padding='max_length', max_length=512, return_tensors='pt')
    
    # Initialize lists to store start and end positions
    start_positions = []
    end_positions = []
    
    # For each example in the batch, calculate the start and end positions of the answer
    for i in range(len(contexts)):
        context = contexts[i]
        answer = examples['answer'][i]
        
        # Find the start and end position of the answer within the context
        start_position = context.find(answer)
        end_position = start_position + len(answer)
        
        # Adjust positions for the tokenized input
        start_token_pos = len(tokenizer.encode(context[:start_position], truncation=True, padding='max_length', max_length=512)) - 1
        end_token_pos = len(tokenizer.encode(context[:end_position], truncation=True, padding='max_length', max_length=512)) - 1
        
        start_positions.append(start_token_pos)
        end_positions.append(end_token_pos)
    
    # Convert the positions to tensors and add them to the inputs
    inputs['start_positions'] = torch.tensor(start_positions).to(device)
    inputs['end_positions'] = torch.tensor(end_positions).to(device)

    return inputs

# 進行批次處理，這次確保處理的是批次資料
train_dataset = train_dataset.map(
    tokenize_and_find_answers, 
    remove_columns=["question", "context", "answer"], 
    num_proc=1,  # Parallel processing
    batched=True,  # Process in batches
    fn_kwargs={'tokenizer': tokenizer}  # Pass tokenizer explicitly
)

val_dataset = val_dataset.map(
    tokenize_and_find_answers, 
    remove_columns=["question", "context", "answer"], 
    num_proc=1,  # Parallel processing
    batched=True,  # Process in batches
    fn_kwargs={'tokenizer': tokenizer}  # Pass tokenizer explicitly
)
```

### 開始訓練
```python
from transformers import BertForQuestionAnswering, Trainer, TrainingArguments

# 載入模型
model = BertForQuestionAnswering.from_pretrained('nlpaueb/legal-bert-base-uncased')

# 設置訓練參數
training_args = TrainingArguments(
    output_dir="./results",
    evaluation_strategy="epoch",
    learning_rate=2e-5,
    fp16=True,
    per_device_train_batch_size=16,
    per_device_eval_batch_size=16,
    num_train_epochs=3,
    weight_decay=0.01,
    logging_dir="./logs",
)

# 設置 Trainer
trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset,
    eval_dataset=val_dataset,
)
 
# 開始訓練
trainer.train()

```
#### 評估
```python
trainer.evaluate()
```
### 進行推理
```python

```
#### 加載新的Validation Data進行測試並切割判例段落防止Token length太長
```python
import os
import pandas as pd
from tqdm import tqdm
from transformers import BertTokenizer

# 設置文件夾路徑
folder_path = 'Data2_Opinion_valid'

# 初始化分詞器
tokenizer = BertTokenizer.from_pretrained('nlpaueb/legal-bert-base-uncased')

def preprocess_and_split_with_overlap(text, max_length=256, stride=128):
    """
    使用滑動窗口切割長文本，保留一定的上下文重疊。
    
    Args:
        text (str): 待切割的文本。
        max_length (int): 每個段落的最大 token 長度。
        stride (int): 滑動窗口的步長，重疊部分長度 = max_length - stride。
        
    Returns:
        list: 切割後的文本段列表。
    """
    tokens = tokenizer.encode(text, truncation=False)  # 不截斷，獲取所有 tokens
    chunks = []
    start = 0
    while start < len(tokens):
        end = min(start + max_length, len(tokens))
        chunk = tokens[start:end]  # 當前窗口的 tokens
        chunks.append(chunk)
        if end == len(tokens):  # 最後一段退出
            break
        start += stride  # 滑動窗口開始位置
    # 將 tokens 解碼回文本
    return [tokenizer.decode(chunk, skip_special_tokens=True) for chunk in chunks]

# 初始化列表存放處理後的數據
processed_data = []

# 讀取文件夾中的 CSV 文件
csv_files = [f for f in os.listdir(folder_path) if f.endswith('.csv')]

# 遍歷 CSV 文件並顯示進度條
for csv_file in tqdm(csv_files, desc="Processing CSV Files"):
    file_path = os.path.join(folder_path, csv_file)
    df = pd.read_csv(file_path)
    
    # 遍歷 DataFrame 中的每行並顯示進度條
    for _, row in tqdm(df.iterrows(), total=df.shape[0], desc=f"Processing {csv_file}", leave=False):
        case_index = row['Case Index']  # 替換成您的列名
        paragraph = row['Paragraph']    # 替換成您的列名
        
        # 對段落進行處理和滑動窗口切割
        chunks = preprocess_and_split_with_overlap(paragraph)
        
        for i, chunk in enumerate(chunks):
            processed_data.append({
                'CSV File': csv_file,  # 添加 CSV 文件名稱
                'Case Index': case_index,
                'Chunk ID': i,
                'Chunk Text': chunk
            })

# 將處理後的數據轉為 DataFrame 並保存
processed_df = pd.DataFrame(processed_data)
processed_df.to_csv('Processed_Opinion.csv', index=False)

print("處理完成，已保存為 'Processed_Opinion.csv'")

```
#### 加載模型、知識圖譜, 定義檢索知識圖譜函數、RAG測試Pipeline、預測函數
```python
import pandas as pd
import json
from tqdm import tqdm
from transformers import BertForQuestionAnswering, BertTokenizer
import torch

# 加載微調後的模型
model = BertForQuestionAnswering.from_pretrained("./fine_tuned_model")
tokenizer = BertTokenizer.from_pretrained("./fine_tuned_model")

# 加載知識圖譜
with open("definition.json", "r", encoding="utf-8-sig") as f:
    knowledge_graph = json.load(f)

# 建立名稱到定義的映射
name_to_definition = {item["Name"]: item["Definition"] for item in knowledge_graph}

print(f"Loaded knowledge graph with {len(knowledge_graph)} entries.")

# 定義檢索知識圖譜的函數

def retrieve_from_knowledge_graph(answer, knowledge_graph):
    """
    根據模型的答案在知識圖譜中進行檢索。
    """
    related_definitions = []
    for entry in knowledge_graph:
        if entry["Name"].lower() in answer.lower():
            related_definitions.append(entry)
    
    return related_definitions if related_definitions else [{"Name": "No Match", "Definition": "No related definition found."}]

# 定義 RAG 測試管線

def rag_test_pipeline(row, model, tokenizer, knowledge_graph):
    """
    單條測試管線，適配切割後的資料。
    """
    csv_file = row['CSV File']  # 新增：來源文件名稱
    case_index = row['Case Index']
    paragraph = row['Chunk Text']
    
    # 定義測試問題
    question = f"What is the judge's opinion regarding entry barriers in case {case_index}?"
    
    # 預測答案
    inputs = tokenizer.encode_plus(question, paragraph, return_tensors="pt", max_length=512, truncation=True)
    outputs = model(**inputs)
    
    answer_start = torch.argmax(outputs.start_logits)
    answer_end = torch.argmax(outputs.end_logits) + 1
    input_ids = inputs["input_ids"].tolist()[0]
    
    answer = tokenizer.convert_tokens_to_string(
        tokenizer.convert_ids_to_tokens(input_ids[answer_start:answer_end])
    )
    
    # 檢索知識圖譜
    related_definitions = retrieve_from_knowledge_graph(answer, knowledge_graph)
    
    return {
        "CSV File": csv_file,  # 新增：來源文件名稱
        "Case Index": case_index,
        "Question": question,
        "Predicted Answer": answer,
        "Knowledge Graph Result": related_definitions
    }

# 批量處理的預測函數

def batch_predict(model, tokenizer, questions, contexts, batch_size=16):
    """
    批量處理問題和上下文，進行預測
    """
    predictions = []
    for i in tqdm(range(0, len(questions), batch_size), desc="Predicting"):
        batch_questions = questions[i:i + batch_size]
        batch_contexts = contexts[i:i + batch_size]
        
        # 編碼輸入
        inputs = tokenizer(batch_questions, batch_contexts, return_tensors="pt", 
                           padding=True, truncation=True, max_length=512)
        inputs = {key: val.to(device) for key, val in inputs.items()}  # 移動到 GPU
        
        # 模型推理
        with torch.no_grad():
            outputs = model(**inputs)
        
        # 提取答案位置
        for j in range(len(batch_questions)):
            start = torch.argmax(outputs.start_logits[j]).item()
            end = torch.argmax(outputs.end_logits[j]).item() + 1
            input_ids = inputs["input_ids"][j].tolist()
            prediction = tokenizer.convert_tokens_to_string(
                tokenizer.convert_ids_to_tokens(input_ids[start:end])
            )
            predictions.append(prediction)
    
    return predictions

```
#### 加載處理過的驗證數據並執行測試
```python
# 加載處理後的數據
valid_data = pd.read_csv("Processed_Opinion.csv")

# 提取問題和上下文，並加入文件名
questions = [f"What is the judge's opinion regarding entry barriers in case {case}?" 
             for case in valid_data["Case Index"]]
contexts = valid_data["Chunk Text"].tolist()
csv_files = valid_data["CSV File"].tolist()  # 使用 'CSV File' 列

print(f"Loaded {len(questions)} samples for validation.")

# 移動模型到 GPU
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)

# 執行批量預測
predicted_answers = batch_predict(model, tokenizer, questions, contexts)

## 知識圖譜檢索
def generate_results_with_csv(valid_data, questions, contexts, csv_files, predicted_answers, knowledge_graph):
    """
    將驗證數據和模型預測結果封裝成包含 Case Index 和 CSV 文件名的結果列表。
    """
    results = []
    for case_index, csv_file, question, context, prediction in zip(valid_data["Case Index"], csv_files, questions, contexts, predicted_answers):
        related_definitions = retrieve_from_knowledge_graph(prediction, knowledge_graph)
        results.append({
            "Case Index": case_index,
            "CSV File": csv_file,  # 包含 CSV 文件名
            "Question": question,
            "Context": context,
            "Predicted Answer": prediction,
            "Knowledge Graph Result": related_definitions
        })
    return results

# 調用函數生成 results
results = generate_results_with_csv(valid_data, questions, contexts, csv_files, predicted_answers, knowledge_graph)

```
```python
# 將結果保存為 JSON 文件
import json
with open("RAG_Test_Results_With_CSV_File.json", "w", encoding="utf-8") as f:
    json.dump(results, f, ensure_ascii=False, indent=4)

print("Results saved to 'RAG_Test_Results_With_CSV_File.json'")

```
#### 查看Match的數據
```python
# 載入保存的結果
import json

with open("RAG_Test_Results_With_CSV_File.json", "r", encoding="utf-8") as f:
    results = json.load(f)

# 過濾有匹配的結果
matched_results = [
    result for result in results if result["Knowledge Graph Result"][0]["Name"] != "No Match"
]

# 列出有匹配的結果
print(f"Found {len(matched_results)} matched results.")
for result in matched_results:
    print("CSV File", result["CSV File"])   
    print(f"Case Index: {result['Case Index']}")  # 包含 Case Index
    print(f"Question: {result['Question']}")
    print(f"Context: {result['Context'][:500]}...")
    print(f"Predicted Answer: {result['Predicted Answer']}")
    print(f"Knowledge Graph Result: {result['Knowledge Graph Result']}")
    print("=" * 50)

```
## 引用Finetune模型直接推理
```python
import os
import pandas as pd
from tqdm import tqdm
from transformers import BertTokenizer

# 設置文件夾路徑
folder_path = 'Data1_Opinion'

# 初始化分詞器
tokenizer = BertTokenizer.from_pretrained('nlpaueb/legal-bert-base-uncased')

def preprocess_and_split_with_overlap(text, max_length=256, stride=128):
    """
    使用滑動窗口切割長文本，保留一定的上下文重疊。
    
    Args:
        text (str): 待切割的文本。
        max_length (int): 每個段落的最大 token 長度。
        stride (int): 滑動窗口的步長，重疊部分長度 = max_length - stride。
        
    Returns:
        list: 切割後的文本段列表。
    """
    tokens = tokenizer.encode(text, truncation=False)  # 不截斷，獲取所有 tokens
    chunks = []
    start = 0
    while start < len(tokens):
        end = min(start + max_length, len(tokens))
        chunk = tokens[start:end]  # 當前窗口的 tokens
        chunks.append(chunk)
        if end == len(tokens):  # 最後一段退出
            break
        start += stride  # 滑動窗口開始位置
    # 將 tokens 解碼回文本
    return [tokenizer.decode(chunk, skip_special_tokens=True) for chunk in chunks]

# 初始化列表存放處理後的數據
processed_data = []

# 讀取文件夾中的 CSV 文件
csv_files = [f for f in os.listdir(folder_path) if f.endswith('.csv')]

# 遍歷 CSV 文件並顯示進度條
for csv_file in tqdm(csv_files, desc="Processing CSV Files"):
    file_path = os.path.join(folder_path, csv_file)
    df = pd.read_csv(file_path)
    
    # 遍歷 DataFrame 中的每行並顯示進度條
    for _, row in tqdm(df.iterrows(), total=df.shape[0], desc=f"Processing {csv_file}", leave=False):
        case_index = row['Case Index']  # 替換成您的列名
        paragraph = row['Paragraph']    # 替換成您的列名
        
        # 對段落進行處理和滑動窗口切割
        chunks = preprocess_and_split_with_overlap(paragraph)
        
        for i, chunk in enumerate(chunks):
            processed_data.append({
                'CSV File': csv_file,  # 添加 CSV 文件名稱
                'Case Index': case_index,
                'Chunk ID': i,
                'Chunk Text': chunk
            })

# 將處理後的數據轉為 DataFrame 並保存
processed_df = pd.DataFrame(processed_data)
processed_df.to_csv('Processed_Opinion_Data1.csv', index=False)

print("處理完成，已保存為 'Processed_Opinion_Data1.csv'")

```

```python
import pandas as pd
import json
from tqdm import tqdm
from transformers import BertForQuestionAnswering, BertTokenizer
import torch

# 加載微調後的模型
model = BertForQuestionAnswering.from_pretrained("./fine_tuned_model")
tokenizer = BertTokenizer.from_pretrained("./fine_tuned_model")

# 加載知識圖譜
with open("definition.json", "r", encoding="utf-8-sig") as f:
    knowledge_graph = json.load(f)

# 建立名稱到定義的映射
name_to_definition = {item["Name"]: item["Definition"] for item in knowledge_graph}

print(f"Loaded knowledge graph with {len(knowledge_graph)} entries.")

# 定義檢索知識圖譜的函數

def retrieve_from_knowledge_graph(answer, knowledge_graph):
    """
    根據模型的答案在知識圖譜中進行檢索。
    """
    related_definitions = []
    for entry in knowledge_graph:
        if entry["Name"].lower() in answer.lower():
            related_definitions.append(entry)
    
    return related_definitions if related_definitions else [{"Name": "No Match", "Definition": "No related definition found."}]

# 定義 RAG 測試管線

def rag_test_pipeline(row, model, tokenizer, knowledge_graph):
    """
    單條測試管線，適配切割後的資料。
    """
    csv_file = row['CSV File']  # 新增：來源文件名稱
    case_index = row['Case Index']
    paragraph = row['Chunk Text']
    
    # 定義測試問題
    question = f"What is the judge's opinion regarding entry barriers in case {case_index}?"
    
    # 預測答案
    inputs = tokenizer.encode_plus(question, paragraph, return_tensors="pt", max_length=512, truncation=True)
    outputs = model(**inputs)
    
    answer_start = torch.argmax(outputs.start_logits)
    answer_end = torch.argmax(outputs.end_logits) + 1
    input_ids = inputs["input_ids"].tolist()[0]
    
    answer = tokenizer.convert_tokens_to_string(
        tokenizer.convert_ids_to_tokens(input_ids[answer_start:answer_end])
    )
    
    # 檢索知識圖譜
    related_definitions = retrieve_from_knowledge_graph(answer, knowledge_graph)
    
    return {
        "CSV File": csv_file,  # 新增：來源文件名稱
        "Case Index": case_index,
        "Question": question,
        "Predicted Answer": answer,
        "Knowledge Graph Result": related_definitions
    }

# 批量處理的預測函數

def batch_predict(model, tokenizer, questions, contexts, batch_size=16):
    """
    批量處理問題和上下文，進行預測
    """
    predictions = []
    for i in tqdm(range(0, len(questions), batch_size), desc="Predicting"):
        batch_questions = questions[i:i + batch_size]
        batch_contexts = contexts[i:i + batch_size]
        
        # 編碼輸入
        inputs = tokenizer(batch_questions, batch_contexts, return_tensors="pt", 
                           padding=True, truncation=True, max_length=512)
        inputs = {key: val.to(device) for key, val in inputs.items()}  # 移動到 GPU
        
        # 模型推理
        with torch.no_grad():
            outputs = model(**inputs)
        
        # 提取答案位置
        for j in range(len(batch_questions)):
            start = torch.argmax(outputs.start_logits[j]).item()
            end = torch.argmax(outputs.end_logits[j]).item() + 1
            input_ids = inputs["input_ids"][j].tolist()
            prediction = tokenizer.convert_tokens_to_string(
                tokenizer.convert_ids_to_tokens(input_ids[start:end])
            )
            predictions.append(prediction)
    
    return predictions

# 加載處理後的數據
valid_data = pd.read_csv("Processed_Opinion_Data1.csv")

# 提取問題和上下文，並加入文件名
questions = [f"What is the judge's opinion regarding entry barriers in case {case}?" 
             for case in valid_data["Case Index"]]
contexts = valid_data["Chunk Text"].tolist()
csv_files = valid_data["CSV File"].tolist()  # 使用 'CSV File' 列

print(f"Loaded {len(questions)} samples for validation.")

# 移動模型到 GPU
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)

# 執行批量預測
predicted_answers = batch_predict(model, tokenizer, questions, contexts)

## 知識圖譜檢索
def generate_results_with_csv(valid_data, questions, contexts, csv_files, predicted_answers, knowledge_graph):
    """
    將驗證數據和模型預測結果封裝成包含 Case Index 和 CSV 文件名的結果列表。
    """
    results = []
    for case_index, csv_file, question, context, prediction in zip(valid_data["Case Index"], csv_files, questions, contexts, predicted_answers):
        related_definitions = retrieve_from_knowledge_graph(prediction, knowledge_graph)
        results.append({
            "Case Index": case_index,
            "CSV File": csv_file,  # 包含 CSV 文件名
            "Question": question,
            "Context": context,
            "Predicted Answer": prediction,
            "Knowledge Graph Result": related_definitions
        })
    return results

# 調用函數生成 results
results = generate_results_with_csv(valid_data, questions, contexts, csv_files, predicted_answers, knowledge_graph)

```

```python
# 將結果保存為 JSON 文件
import json
with open("RAG_Test_Results_With_CSV_File_Data1.json", "w", encoding="utf-8") as f:
    json.dump(results, f, ensure_ascii=False, indent=4)

print("Results saved to 'RAG_Test_Results_With_CSV_File_Data1.json'")

# 查看部分結果
for result in results[:5]:
    print("CSV File", result["CSV File"])
    print("Case Index:", result["Case Index"])  # 新增 Case Index 的輸出
    print("Question:", result["Question"])
    print("Predicted Answer:", result["Predicted Answer"])
    print("Knowledge Graph Result:", result["Knowledge Graph Result"])
    print("=" * 50)

```
#### 顯示Match數據
```python
# 載入保存的結果
import json

with open("RAG_Test_Results_With_CSV_File_Data1.json", "r", encoding="utf-8") as f:
    results = json.load(f)

# 過濾有匹配的結果
matched_results = [
    result for result in results if result["Knowledge Graph Result"][0]["Name"] != "No Match"
]

# 列出有匹配的結果
print(f"Found {len(matched_results)} matched results.")
for result in matched_results:
    print("CSV File", result["CSV File"])   
    print(f"Case Index: {result['Case Index']}")  # 包含 Case Index
    print(f"Question: {result['Question']}")
    print(f"Context: {result['Context'][:500]}...")
    print(f"Predicted Answer: {result['Predicted Answer']}")
    print(f"Knowledge Graph Result: {result['Knowledge Graph Result']}")
    print("=" * 50)

```
## 所有DATA檢索與擴展知識圖譜
```python
import os
import pandas as pd
import json
from tqdm import tqdm
from transformers import BertForQuestionAnswering, BertTokenizer
import torch

# 加載微調後的模型
model = BertForQuestionAnswering.from_pretrained("./fine_tuned_model")
tokenizer = BertTokenizer.from_pretrained("./fine_tuned_model")

# 加載知識圖譜
with open("definition_moreinfo.json", "r", encoding="utf-8-sig") as f:
    knowledge_graph = json.load(f)

# 建立名稱到定義的映射
name_to_definition = {item["Name"]: item["Definition"] for item in knowledge_graph}

print(f"Loaded knowledge graph with {len(knowledge_graph)} entries.")

# 定義檢索知識圖譜的函數
def retrieve_from_knowledge_graph(answer, knowledge_graph):
    related_definitions = []
    for entry in knowledge_graph:
        # 獲取名稱和同義詞
        synonyms = entry.get("Synonyms", [])
        terms_to_match = [entry["Name"]] + synonyms

        # 名稱或同義詞匹配
        if any(term.lower() in answer.lower() for term in terms_to_match):
            related_definitions.append(entry)
            continue

        # 定義關鍵詞匹配
        if entry["Definition"].lower() in answer.lower():
            related_definitions.append(entry)

    return related_definitions if related_definitions else [{"Name": "No Match", "Definition": "No related definition found."}]

# 定義批量處理函數，新增檢索結合
def batch_predict_with_retrieval(model, tokenizer, questions, contexts, knowledge_graph, batch_size=16):
    predictions = []
    for i in tqdm(range(0, len(questions), batch_size), desc="Predicting"):
        batch_questions = []
        batch_contexts = contexts[i:i + batch_size]

        # 檢索知識並組合問題
        for question, context in zip(questions[i:i + batch_size], batch_contexts):
            # 模擬初步回答以檢索知識
            retrieved_knowledge = retrieve_from_knowledge_graph(context, knowledge_graph)
            retrieved_text = " ".join([item["Definition"] for item in retrieved_knowledge if item["Name"] != "No Match"])
            full_question = f"{retrieved_text} {question}"
            batch_questions.append(full_question)

        # 編碼輸入
        inputs = tokenizer(batch_questions, batch_contexts, return_tensors="pt", 
                           padding=True, truncation=True, max_length=512)
        inputs = {key: val.to(device) for key, val in inputs.items()}  # 移動到 GPU

        with torch.no_grad():
            outputs = model(**inputs)

        # 解碼回答
        for j in range(len(batch_questions)):
            start = torch.argmax(outputs.start_logits[j]).item()
            end = torch.argmax(outputs.end_logits[j]).item() + 1
            input_ids = inputs["input_ids"][j].tolist()
            prediction = tokenizer.convert_tokens_to_string(
                tokenizer.convert_ids_to_tokens(input_ids[start:end])
            )
            predictions.append(prediction)
    return predictions

# 遞迴處理所有處理過的 CSV 文件
folder_path = "Processed_Data_Opinion"
all_results = []
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)

for file in tqdm(os.listdir(folder_path), desc="Processing Files"):
    if file.endswith(".csv"):
        file_path = os.path.join(folder_path, file)
        valid_data = pd.read_csv(file_path)

        questions = [f"What is the judge's opinion regarding entry barriers in case {case}?" 
                     for case in valid_data["Case Index"]]
        contexts = valid_data["Chunk Text"].tolist()
        csv_files = [file] * len(questions)  # 文件名對應每個樣本

        predicted_answers = batch_predict_with_retrieval(model, tokenizer, questions, contexts, knowledge_graph)

        for case_index, csv_file, question, context, prediction in zip(valid_data["Case Index"], csv_files, questions, contexts, predicted_answers):
            related_definitions = retrieve_from_knowledge_graph(prediction, knowledge_graph)
            all_results.append({
                "Case Index": case_index,
                "CSV File": csv_file,
                "Question": question,
                "Context": context,
                "Predicted Answer": prediction,
                "Knowledge Graph Result": related_definitions
            })

# 保存所有結果
with open("All_RAG_Results.json", "w", encoding="utf-8") as f:
    json.dump(all_results, f, ensure_ascii=False, indent=4)

print("All results saved to 'All_RAG_Results.json'")

```
```python
import json

# 載入所有結果
with open("All_RAG_Results.json", "r", encoding="utf-8") as f:
    results = json.load(f)

# 過濾有匹配的結果
matched_results = [
    result for result in results if any(res["Name"] != "No Match" for res in result["Knowledge Graph Result"])
]

# 列出匹配的結果數量
print(f"Found {len(matched_results)} matched results.")

# 保存匹配結果到新文件
output_file = "Matched_ALL_DATA.json"
with open(output_file, "w", encoding="utf-8") as f:
    json.dump(matched_results, f, ensure_ascii=False, indent=4)

# 顯示部分匹配結果
if matched_results:
    print("\nDisplaying the first 5 matched results:")
    for result in matched_results[:5]:  # 只顯示前5個匹配結果
        print("=" * 50)
        print(f"CSV File: {result['CSV File']}")
        print(f"Case Index: {result['Case Index']}")
        print(f"Question: {result['Question']}")
        print(f"Context: {result['Context'][:300]}...")  # 限制輸出長度
        print(f"Predicted Answer: {result['Predicted Answer']}")
        print("Knowledge Graph Result:")
        for kg_result in result["Knowledge Graph Result"]:
            print(f"  - Name: {kg_result['Name']}")
            print(f"    Definition: {kg_result['Definition']}")
        print("=" * 50)
else:
    print("No matched results found.")

print(f"Matched results saved to '{output_file}'")

```
