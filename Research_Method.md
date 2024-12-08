因為算力有限, 如果拿全部或一半的資料進去Train, 電腦的內存會爆掉, 所以拿10.74%(999個判例)去Fine-tuned pre-trained model(LegalBert), 因為每個判例的Opinion都非常長, 而模型訓練最多的Token限制是512, Token就是一個單詞的意思, 所以將Opinion以256個Tokes為裁切標準進行切割成段落丟進去訓練, 訓練的目標是讓LLM知道這些清理完的CSV文本是Opinion, 所以會創立一個QA Pair:        
question = f"What is the judge's opinion regarding entry barriers in case {case_index}?"
question_prosecutor = f"What is the prosecutor's argument regarding entry barriers in case {case_index}?"
讓LLM訓練這些法官或檢察官的意見, 當我input某個段落的Opinion時, LLM能快速判別該段落為法官或檢察官的Opinion.
將Fine tuned模型進行保存
接下來要加入RAG檢索知識圖譜進行預測, 資料的話是拿32.22%(2998)個判例下去預測, 這邊基於Fine tune的經驗, 如果只是單純截斷文本可能會損失上下文和