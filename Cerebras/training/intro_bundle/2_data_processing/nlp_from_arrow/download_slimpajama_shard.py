import datasets as ds

slim_pj = ds.load_dataset("DKYoon/SlimPajama-6B", cache_dir="./hf_cache/",
        split="train[:200000]")
print(slim_pj)
slim_pj.save_to_disk("./1_arrow/")
