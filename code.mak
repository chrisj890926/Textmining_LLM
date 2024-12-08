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
