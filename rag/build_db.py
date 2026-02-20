import json
import os
from rag_engine import RAGManager

DATA_FILE = r"d:\Junior\ImageToArkTS\rag\processed_data.jsonl"

def main():
    if not os.path.exists(DATA_FILE):
        print(f"Error: Processed data file not found at {DATA_FILE}")
        print("Please run prepare_data.py first.")
        return

    print(f"Loading data from {DATA_FILE}...")
    chunks = []
    with open(DATA_FILE, 'r', encoding='utf-8') as f:
        for line in f:
            if line.strip():
                chunks.append(json.loads(line))
            
    print(f"Loaded {len(chunks)} chunks.")
    
    rag = RAGManager()
    
    # Check if we should append or overwrite (for now, let's just add)
    # Ideally, we might want to clean the collection first if rebuilding
    # count = rag.collection.count()
    # if count > 0:
    #     print(f"Warning: Collection already has {count} documents.")
    
    print("Starting indexing process...")
    try:
        rag.add_documents(chunks)
        print("Indexing complete!")
    except Exception as e:
        print(f"An error occurred during indexing: {e}")
        print("Ensure you have 'chromadb' and 'sentence-transformers' installed.")
        print("pip install chromadb sentence-transformers")

if __name__ == "__main__":
    main()
