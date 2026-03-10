import datasets as ds

olmo = ds.load_dataset("DKYoon/SlimPajama-6B", cache_dir="./hf_cache/",
        split="train[:200000]")
print(olmo)
olmo.save_to_disk("./1_arrow/")
