import os
import json
import chromadb
from chromadb.utils import embedding_functions
from typing import List, Dict, Any

# Configuration
PERSIST_DIRECTORY = r"d:\Junior\ImageToArkTS\rag\chroma_db"
COLLECTION_NAME = "arkts_api_docs"

class RAGManager:
    def __init__(self, persist_dir=PERSIST_DIRECTORY):
        self.persist_dir = persist_dir
        # Initialize Client
        # PersistentClient saves to disk
        self.client = chromadb.PersistentClient(path=persist_dir)
        
        # Use a multilingual model since docs are mixed (Chinese/English)
        # This will download the model (~470MB) on first run if not cached.
        print("Initializing embedding function...")
        
        os.environ["HF_HUB_OFFLINE"] = "1"
        
        self.embedding_func = embedding_functions.SentenceTransformerEmbeddingFunction(
            model_name="paraphrase-multilingual-MiniLM-L12-v2"
        )
        
        self.collection = self.client.get_or_create_collection(
            name=COLLECTION_NAME,
            embedding_function=self.embedding_func
        )

    def add_documents(self, chunks: List[Dict]):
        """
        Adds parsed document chunks to the vector database.
        """
        ids = []
        documents = []
        metadatas = []
        
        for i, chunk in enumerate(chunks):
            # Create a unique ID. Ideally hash of content, but index is okay for static set
            # We combine api_name and index to ensure uniqueness
            doc_id = f"doc_{i}"
            
            ids.append(doc_id)
            documents.append(chunk['content'])
            
            # Metadata must be simple key-value pairs (str, int, float, bool)
            meta = {
                "source": chunk.get('source', ''),
                "api_name": chunk.get('api_name', ''),
                "item_name": chunk.get('item_name', ''),
                "type": chunk.get('type', 'unknown')
            }
            metadatas.append(meta)
            
        # Add to collection in batches to avoid memory issues and provide progress
        batch_size = 64 # Smaller batch size is safer for embedding generation
        total = len(ids)
        
        for i in range(0, total, batch_size):
            end = min(i + batch_size, total)
            print(f"Embedding and adding batch {i} to {end} / {total}...")
            self.collection.add(
                ids=ids[i:end],
                documents=documents[i:end],
                metadatas=metadatas[i:end]
            )
            
    def query(self, query_text: str, n_results: int = 5) -> Dict[str, Any]:
        """
        Queries the database for most relevant documents.
        """
        results = self.collection.query(
            query_texts=[query_text],
            n_results=n_results
        )
        return results

    def format_results(self, results) -> str:
        """
        Helper to format db results into a context string for LLM.
        """
        formatted_context = ""
        # Results structure is { 'documents': [[doc1, doc2...]], 'metadatas': [[meta1...]] }
        if not results['documents']:
            return "No relevant documents found."
            
        docs = results['documents'][0]
        metas = results['metadatas'][0]
        
        for i, doc in enumerate(docs):
            source = metas[i].get('source', 'Unknown')
            api_name = metas[i].get('api_name', '')
            formatted_context += f"--- Reference {i+1} (Source: {api_name}) ---\n{doc}\n\n"
            
        return formatted_context
