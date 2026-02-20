import os
import time
from rag_engine import RAGManager
from openai import OpenAI
from dotenv import load_dotenv


load_dotenv(dotenv_path=os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env'))

client = OpenAI(

    api_key=os.environ.get("OPENAI_API_KEY"),
    base_url="https://dashscope.aliyuncs.com/compatible-mode/v1"
)


def generate_llm_response(prompt: str, model: str = "deepseek-v3.2") -> str:
    """
    Generates response using OpenAI compatible API.
    """
    
    try:
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": "You are a helpful expert on HarmonyOS (ArkTS) development."},
                {"role": "user", "content": prompt}
            ]
        )
        return response.choices[0].message.content
    except Exception as e:
        return f"[[Error generating response: {e}]]"

def main():
    print("Initializing RAG System (loading vector db)...")
    try:
        rag = RAGManager()
    except Exception as e:
        print(f"Failed to initialize RAG: {e}")
        return

    print("\n=== ArkTS RAG System ===")
    print("Type 'exit' to quit.")
    
    while True:
        query = input("\nEnter your question > ")
        if query.lower() in ['exit', 'quit']:
            break
        if not query.strip():
            continue
            
        start_time = time.time()
        
        # 1. Retrieve
        print("\n🔍 Retrieving relevant docs...")
        results = rag.query(query, n_results=5)
        context_str = rag.format_results(results)
        
        # 2. Results display
        print("\n📄 Retrieved Context:")
        print("-" * 50)
        print(context_str[:2000] + ("..." if len(context_str) > 2000 else ""))
        print("-" * 50)
        
        # 3. Validation / Comparison Prompt
        # We can simulate the comparison here
        
        rag_prompt = f"""
Please answer the user's question about HarmonyOS development based on the provided context below.

[Context Begin]
{context_str}
[Context End]

[User Question]
{query}

Provide a code example if applicable.
"""

        no_rag_prompt = f"""
Please answer the user's question about HarmonyOS development.
Assume you are using the latest API version 10/11/12.

[User Question]
{query}

Provide a code example if applicable.
"""
        
        print("\n🤖 Generating Answers (Comparison)...")
        

        print("\n--- Model Only (No RAG) ---")
        ans_no_rag = generate_llm_response(no_rag_prompt)
        print(ans_no_rag)
        
        print("\n--- Model + RAG ---")
        ans_rag = generate_llm_response(rag_prompt)
        print(ans_rag)


        print(f"\n⏱️ Total time: {time.time() - start_time:.2f}s")

if __name__ == "__main__":
    main()
