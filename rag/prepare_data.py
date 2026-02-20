import json
import os
from typing import List, Dict

# Configuration
DATA_DIR = r"d:\Junior\ImageToArkTS\rag\updated_reference_cleaned"
OUTPUT_FILE = r"d:\Junior\ImageToArkTS\rag\processed_data.jsonl"

def load_json_files(directory: str) -> List[str]:
    json_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".json"):
                json_files.append(os.path.join(root, file))
    return json_files

def process_file(file_path: str) -> List[Dict]:
    chunks = []
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        api_name = data.get("api_name", "Unknown API")
        overview = data.get("overview", {})
        # Handle cases where overview is just a string or missing
        if isinstance(overview, dict):
            overview_text = overview.get("zh", overview.get("en", ""))
        else:
            overview_text = str(overview) if overview else ""

        # Some files might not have import_from, or it's empty
        import_stmt = data.get("import_from", "")
        
        items = data.get("items", [])
        
        # Strategy: Create a document for the module overview itself
        # This helps when the user asks "What is api X?"
        module_doc = {
            "source": file_path,
            "type": "module_overview",
            "api_name": api_name,
            "item_name": "Overview",
            "content": f"Module: {api_name}\nImport: {import_stmt}\nOverview: {overview_text}"
        }
        chunks.append(module_doc)

        for item in items:
            item_name = item.get("name", "")
            item_type = item.get("type", "")
            if not item_name:
                continue
                
            # Construct description
            desc_obj = item.get("description", {})
            if isinstance(desc_obj, dict):
                desc_text = desc_obj.get("zh", desc_obj.get("en", ""))
            else:
                desc_text = str(desc_obj) if desc_obj else ""
            
            # Signature
            signature = item.get("signature", "")
            
            # Examples
            examples = item.get("examples", [])
            examples_text = ""
            if examples:
                formatted_examples = []
                for ex in examples:
                     formatted_examples.append(str(ex))
                examples_text = "\nExample:\n" + "\n".join(formatted_examples)
            
            # Parameters/Properties tables logic
            details_text = ""
            tables = item.get("tables", [])
            for table in tables:
                table_data = table.get("data", {})
                headers = table_data.get("headers", [])
                rows = table_data.get("rows", [])
                
                if headers and rows:
                    # Append header row
                    details_text += "\nTable Details:\n" + " | ".join(headers) + "\n"
                    details_text += "-" * (len(headers) * 10) + "\n" # specific separator not strictly needed for embedding but helps reading
                    
                    for row in rows:
                        # Row can be a dict where keys match headers
                        if isinstance(row, dict):
                            # Try to match headers to keys. Note: JSON keys might be Chinese "名称" vs English "Name"
                            # The headers list tells us what keys to look for.
                            row_values = []
                            for h in headers:
                                val = row.get(h, "")
                                row_values.append(str(val))
                            details_text += " | ".join(row_values) + "\n"
                        elif isinstance(row, list):
                            details_text += " | ".join([str(c) for c in row]) + "\n"

            # Combine into a single text chunk
            # We explicitly include the module import in every item's chunk so the retriever knows how to use it.
            # We format it somewhat like code/docstring to help the LLM understand structure.
            content = f"""
Module: {api_name}
Item: {item_name}
Type: {item_type}
Import: {import_stmt}
Signature: {signature}

Description:
{desc_text}

{details_text}

{examples_text}
""".strip()
            
            chunk = {
                "source": file_path,
                "type": "api_item",
                "api_name": api_name,
                "item_name": item_name,
                "content": content
            }
            chunks.append(chunk)
            
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        
    return chunks

def main():
    if not os.path.exists(DATA_DIR):
        print(f"Data directory not found: {DATA_DIR}")
        return

    files = load_json_files(DATA_DIR)
    print(f"Found {len(files)} JSON files.")
    
    all_chunks = []
    for i, file_path in enumerate(files):
        # Optional: Print progress every 10 files
        if i % 10 == 0:
            print(f"Processing {i}/{len(files)}...")
        file_chunks = process_file(file_path)
        all_chunks.extend(file_chunks)
        
    print(f"Finished processing. Generated {len(all_chunks)} chunks.")
    
    # Save to JSONL for easy inspection/loading
    try:
        with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
            for chunk in all_chunks:
                f.write(json.dumps(chunk, ensure_ascii=False) + '\n')
        print(f"Saved processed data to {OUTPUT_FILE}")
    except Exception as e:
        print(f"Error saving to file: {e}")

if __name__ == "__main__":
    main()
