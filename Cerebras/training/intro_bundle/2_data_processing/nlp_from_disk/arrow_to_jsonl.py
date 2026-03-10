from datasets import load_from_disk

if __name__ == "__main__":
    src_root = "./1_arrow/"
    tgt_path = "./2_jsonl/slimpajama_slice.jsonl"

    ds = load_from_disk(src_root)
    ds.to_json(tgt_path)
