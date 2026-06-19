# Training on the Cerebras Wafer-Scale Cluster

To access Cerebras CS-3 deployed at ALCF, please submit a DD allocation request. Once it is approved, you may use the following steps. 

## Connecting to CS-3
Users connect via SSH to the login node, cerebras.alcf.anl.gov and then ssh to one of two user nodes with naming convention `cer-usn-0X`.

The trees /home, /projects, and /software are shared across the login nodes and user nodes, the relevant cluster infrastructure nodes, and all ALCF AI testbed platforms.

To connect to the Wafer-Scale Cluster:

ssh to the login node:

```bash
ssh ALCFUserID@cerebras.ai.alcf.anl.gov
```

Then ssh to a cerebras user node:

```bash
ssh cer-usn-01
or
ssh cer-usn-02
```

## Environment and Cerebras Modelzoo setup
Throughout the training portion of this tutorial, we'll be leveraging a pre-assembled set of example scripts and commands (the "intro_bundle") covering common workflows for new users to get familiar with the WSC. It includes numbered subdirectories corresponding to the order in which we recommend working through them.

For convenience, the intro bundle is included in this repository. You can also copy the latest version to a directory of your choice via:

```bash
scp -r /software/cerebras/training_intro_bundle /My/Path/
```

then `cd /My/Path` and proceed as below. 

### Virtual environment setup
First thing's first -- we need an isolated environment to track and manage all of our python packages! Start by entering the environment setup directory and examining the steps for environment setup:

```bash
cd training_intro_bundle/1_env_setup/
# Contains all necessary steps in a runnable script, with explanatory comments!
cat setup.sh
```

When you're ready to set up your environment, just execute the script via:
```bash
# Source is necessary to keep the environment active after the script has finished.
source setup.sh

# If you need to tear down your virtual environment later for whatever reason:
sh cleanup.sh
```

Note that the modelzoo has a handy, unified command-line interface (CLI) that can be used to manage nearly all of the core tasks involved in preparing data, converting checkpoints, training and evaluating, models, and more! We'll be going over common workflows in this tutorial, but you can learn more about the CLI (and the modelzoo in general) at `training-docs.cerebras.ai`.

## Data Preprocessing
Before we train a model, we need some data to work with! The intro bundle has a couple examples of how we can work with natural language data from either the Huggingface Hub or locally on-disk.

### Preprocessing from Huggingface

```bash
cd ../2_data_processing/nlp_from_hf/
```

Looking inside `run.sh`, we see the command to invoke the Cerebras Modelzoo's built-in data preprocessing logic is quite compact:

```bash
cszoo data_preprocess run --config preprocess.yaml
```

This command will stay constant no matter what data preprocessing we run; all the actual logic is determined inside the yaml config, so let's take a lot at what's happening inside:

```yaml
setup:
    data:
        type: "huggingface"
        source: "karpathy/tiny_shakespeare"
        split: "train"
    mode: "pretraining"
    output_dir: "./shakespeare_h5/"
    processes: 32
```

So far, so good. The modelzoo lets us point at arbitrary datasets on the huggingface hub using their unique identifier, define what split (or not, if we want them all) to download, whether we're prepping the data for pretraining or finetuning, and specify an output directory.

Note that the outputs of this process are hdf5 files, which we strongly recommend you use whenever possible. The CS3's extremely high IO bandwidth and low compute latency means we chew through data *fast*, and starvation from slow dataloaders is a much more common issue than similar workloads being run on GPUs. When looking at the next preprocessing workflow, we'll examine how we can convert an intermediate data format (jsonlines) to this hdf5 format easily.

```yaml
processing:
    huggingface_tokenizer: "NousResearch/Meta-Llama-3-8B-Alternate-Tokenizer"
    write_in_batch: True
    read_hook: "cerebras.modelzoo.data_preparation.data_preprocessing.hooks:text_read_hook"
    read_hook_kwargs:
        text_key: "text"
    use_ftfy: True

dataset:
    use_vsl: False
    pack_sequences: True
```

This defines the meat of the preprocessing logic. Like with the dataset, we can specify a `huggingface_tokenizer` using its unique identifier on the Huggingface Hub. We can use arbitrary, custom on-disk tokenizers as well, it just takes a couple additional fields -- see our training documentation for more info.

The load-bearing portion here is the `read_hook`, which defines how the preprocessor makes sense of the key-value map of a given row in our dataset. In more sophisticated cases, like visual question answering (VQA) preprocessing, we need to specify what strings a given dataset is using to refer to a conversation "turn", images, and so on. In our case, since we're targeting simple GPT-style pretraining, we just want to pull the "text" field from our dataset and use that. The remaining settings are all pretty self-explanatory, though as always please consult the docs for a full accounting of what's possible. For now, `sh run.sh` will preprocess the data.

### Preprocessing from Local Data

The above workflow is all well and good if we already have a dataset of interest on the Huggingface Hub, but what if we have custom data we've prepared on-disk or have in a weird file format? The flow ends up looking quite similar, just with an extra step up front.

Let's begin:

```bash
cd ../nlp_from_disk/
cat run.sh

# Output:
# python download_slimpajama_shard.py
# python arrow_to_jsonl.py
# cszoo data_preprocess run --config preprocess.yaml
```

The final step is the same as before -- running `data_preprocess run`, just with a different preprocessing config. The first two steps require a bit of context.

Before, we talked about how the `data_read_hook` makes sense of a given row from a dataset, laid out as a key-value map. In order to go from raw data files, which can be quite diverse, to this standardized row-dictionary form, the modelzoo's data preprocessing logic has a `Reader` which supports a number of data formats which it already knows how to parse:

```bash
.jsonl, .json.gz, .jsonl.zst, .jsonl.zst.tar, .parquet, .txt, .fasta
```

You could hypothetically add new functionality to the `Reader`, but in practice it's very rare that a file format can't be converted to one of the above.

`download_slimpajama_shard.py` just fetches a small slice of data from huggingface, then saves it to disk as an Apache arrow table -- a format unsupported by our `Reader`. In reality, you would probably have the dataset already on disk in some arbitrary format.

```python
import datasets as ds

olmo = ds.load_dataset("DKYoon/SlimPajama-6B", cache_dir="./hf_cache/",
        split="train[:200000]")
print(olmo)
olmo.save_to_disk("./1_arrow/")
```

The part that really matters is `arrow_to_jsonl.py`, where we convert the unsupported arrow dataset into jsonlines, which can then be efficiently read and converted into hdf5 by the modelzoo. In our case this process is trivial because Huggingface's `datasets` library can convert from arrow straight to jsonlines, but you could define your own script to convert from your source format to jsonlines, parquet, and so on.

```python
from datasets import load_from_disk

if __name__ == "__main__":
    src_root = "./1_arrow/"
    tgt_path = "./2_jsonl/slimpajama_slice.jsonl"

    ds = load_from_disk(src_root)
    ds.to_json(tgt_path)
```

Now that our dataset is in a `Reader`-friendly format, we can finish processing our data as before with `preprocess.yaml`:

```yaml
  mode: "pretraining" #or "finetuning"
  output_dir: "./3_h5/" 
  processes: 48 #desired number of CPU cores, set to 0 for default number of cores available

processing:
  huggingface_tokenizer: "meta-llama/Llama-3.3-70B-Instruct"
  read_hook: "cerebras.modelzoo.data_preparation.data_preprocessing.hooks:text_read_hook"
  read_hook_kwargs:
    text_key: "text"
  resume_from_checkpoint: False
  max_seq_length: 2048
  read_chunk_size: 10240
  write_chunk_size: 40960
  shuffle: False
  shuffle_seed: 0
  ftfy_normalizer: NFC
  use_ftfy: False
  wikitext_detokenize: False

dataset:
  use_vsl: False
  pack_sequences: True
```

Aside from a few extra settings specifying how much data to read and write at once, this is basically identical to our previous example! All of the real work happened in getting our data into a supported format first, then letting the modelzoo transform it into optimized hdf5. As before, `sh run.sh` will execute all the above steps and leave us with a usable hdf5 dataset.

## Model Training

Now that we have datasets in hand, let's learn about training models!

```bash
cd ../3_training/nlp/
ls
# cleanup.sh
# llama3_8b_msl_2k.yaml
# llama3_tiny_msl_2k.yaml
# mixtrail_6x7b_msl_2k.yaml
# run.sh
```

A given mode training job (or experiment) is parameterized in full by a single yaml configuration file. This file is responsible for defining dataloader behavior, model structure and hyperparameters, optimizer type and parameters, and more! Actually executing a job is even more straightforward that our data preprocessing step:

```bash
cszoo fit llama3_tiny_msl_2k.yaml
```

As before, a simple `cszoo` command followed by `fit` and the path to our experiment config in question is all we need -- the modelzoo handles the rest!

Before we actually execut `cszoo fit`, let's take a look at the yaml config and its key sections with `cat llama3_tiny_msl_2k.yaml`.

For a full treatment on the various yaml config options, please see `https://training-docs.cerebras.ai/rel-2.9.0/model-zoo/trainer-configuration-overview`.

```yaml
trainer:
  fit:
    train_dataloader:
      batch_size: 16
      data_dir: /home/fungerous/github/ALCF-AIAccelerators-tutorial/Cerebras/training/intro_bundle/2_data_processing/nlp_from_hf/shakespeare_h5/
      data_processor: GptHDF5MapDataProcessor
      num_workers: 8
      persistent_workers: true
      prefetch_factor: 10
      shuffle: false
      shuffle_seed: 1337
    val_dataloader: &id001
      batch_size: 16
      data_dir: /home/fungerous/github/ALCF-AIAccelerators-tutorial/Cerebras/training/intro_bundle/2_data_processing/nlp_from_hf/shakespeare_h5/
      data_processor: GptHDF5MapDataProcessor
      num_workers: 0
      shuffle: false
```

Note that I need to provide a full path to my data directory -- because the Wafer-Scale Cluster orchestrates a bunch of different nodes and processes to cover data streaming, weight streaming, optimization, and so on, it's not uncommon to run into issues if we specify relative paths. Feel free to modify your path to point at either of the hdf5 datasets you generated in previous steps -- it should work the same either way!

The rest of the options all correspond to standard PyTorch dataloader settings, with the exception of `data_processor: GptHDF5MapDataProcessor`, which corresponds to a modelzoo class with dataset and dataloader boilerplate for GPT-style, HDF5 datasets which support random access as opposed to a straight-through `IterableDataset` workflow. Because all of these dataloaders are executed on commodity CPU servers, these `DataProcessor`s are just boilerplate around bog standard PyTorch data-loading code.

To understand more about how these classes are structured and learn how you can define your own `DataProcessor`, I encourage you to look around `https://github.com/Cerebras/modelzoo/tree/main/src/cerebras/modelzoo/data` (or the local equivalent in your own modelzoo clone). For training GPT-style models (GPT3, Llama, etc), `GPTHDF5MapDataProcessor` fits the bill the vast majority of the time.

```yaml
init:
    backend:
      backend_type: CSX
      cluster_config:
        num_csx: 1
    callbacks:
    - ScopedTrainFlags:
        csx.performance.micro_batch_size: 16
    - ScopedValidateFlags:
        csx.performance.micro_batch_size: 16
    - ComputeNorm: {}
    - LoadCheckpointStates:
        load_checkpoint_states: model
    checkpoint:
      disable_strict_checkpoint_loading: true
      save_initial_checkpoint: false
      steps: 1000000
    logging:
      log_steps: 1
    loop:
      eval_steps: 2
      max_steps: 12000
      eval_frequency: 2384
```

Here we configure several meta-settings about our job, including the type of hardware (`CSX` -- sometimes we'll specify `CPU` for troubleshooting purposes), the number of CS-3s to use out of the four at ALCF (`cluster_config.num_csx`), how frequently to save checkpoints; log training progress; and conduct model validation loops, as well as how many training steps to train for.

Note that all we have to do in order to scale up our training jobs is increase `backend.cluster_config.num_csx`. Because the Wafer-Scale Cluster scales highly efficiently using only data parallelism, we do not need to worry about how our model implementation's efficiency changes as the number of systems increases, and there are no additional hyperparameters we need to refine in order to ensure good scaling performance. With very rare corner-case exceptions, ML practicioners do not need to worry about how their model performs at 1 vs 4 vs 64 or more CS-3 systems. This frees us up to tailor our experiments to be "ML-first" rather than making experimental concessions based on engineering constraints.

The `csx.performance.micro_batch_size` fields are specifying the actual batch size the model processes during each forward pass. If it's less than the `batch_size` specified by our dataloader fields from before, then the job will use gradient accumulation across the full `batch_size`. This way we can maintain a consistent "mathematical batch size" while accounting for a micro batch size that's fastest or best suits the model's memory constraints. We can also specify `micro_batch_size: 'auto'` to ask to the compiler to search for a *reasonable* value, or `micro_batch_size: 'explore'` to have the compiler search for the *best, fastest* value. Note that conducting this search can take a while, but if you're running a large training job it can be worth finding the ideal micro batch size first!

```yaml
model:
      name: llama
      attention_dropout_rate: 0.0
      attention_module: multiquery_attention
      attention_type: scaled_dot_product
      dropout_rate: 0.0
      embedding_dropout_rate: 0.0
      embedding_layer_norm: false
      extra_attention_params:
        num_kv_groups: 8
      filter_size: 14336
      hidden_size: 4096
      initializer_range: 0.02
      layer_norm_epsilon: 1.0e-05
      loss_scaling: num_tokens
      loss_weight: 1.0
      max_position_embeddings: 2048
      nonlinearity: swiglu
      norm_type: rmsnorm
      num_heads: 32
      num_hidden_layers: 2
      pos_scaling_extra_args:
        high_freq_factor: 4.0
        low_freq_factor: 1.0
        original_max_position_embeddings: 2048
      pos_scaling_factor: 8.0
      pos_scaling_type: llama3
      position_embedding_type: rotary
      rope_theta: 500000.0
      rotary_dim: 128
      share_embedding_weights: false
      use_bias_in_output: false
      use_ffn_bias: false
      use_ffn_bias_in_attention: false
      use_projection_bias_in_attention: false
      vocab_size: 128256
```

As you can see, within the general `llama` class definition, we have pretty broad flexibility in defining our model's layer structure and size, attention implementation, vocab and max sequence length, and much more just via this config. This makes is extremely easy to define a large slew of ablation experiments, provided they have base implementations inside the modelzoo.

If we explore 

`https://github.com/Cerebras/modelzoo/blob/main/src/cerebras/modelzoo/models/nlp/llama/model.py`

to learn more about the base `llama` implementation, we'll see that all the core logic is actually inherited from the modelzoo's `gpt2` implementation -- this tracks, seeing as how in most cases, gpt-style models have identical structure and behavior aside from some small tweaks. 

This means we can actually refer to 

`https://github.com/Cerebras/modelzoo/tree/main/src/cerebras/modelzoo/models/nlp/gpt2`

to get a sense for how our llama models are implemented under the hood. Model porting is a more advanced topic than we have time for today, but please see

`https://training-docs.cerebras.ai/rel-2.9.0/model-zoo/migration/porting-pytorch-models-to-cerebras`

for a more thorough treatment of customizing or porting modelzoo models.

Returning to our yaml config:

```yaml
    optimizer:
      Adam:
        betas:
        - 0.9
        - 0.95
        correct_bias: true
        weight_decay: 0.1
    precision:
      enabled: true
      fp16_type: cbfloat16
      log_loss_scale: true
      loss_scaling_factor: dynamic
      max_gradient_norm: 1.0
    schedulers:
    - LinearLR:
        initial_learning_rate: 0.0
        end_learning_rate: 7.5e-05
        total_iters: 4768
    seed: 1
  validate:
    val_dataloader: *id001
  validate_all:
    val_dataloaders: *id001
```

We see that the modelzoo gives us ready access to fields for managing not just our optimizer, but also learning schedulers and floating-point precision settings. All are quite consistent with what you might see in a standard PyTorch job, though do consult our docs if you have more questions about `cbfloat` and Cerebras-specific precision settings.

## Job Submission and Queueing

Now that we've had a chance to examine our training job's configuration, we can go ahead and submit our job using `cszoo fit` or via `run.sh`.

The CS-3 cluster has its own Kubernetes-based system for job submission and queuing. Once we've submitted a job using the modelzoo CLI, it is automatically queued and then executed.

------

Use Cerebras' cluster command line tool `csctl` to get addional information about jobs:

* Jobs that have not yet completed can be listed as
    `(r2.9) $ csctl get jobs`
* Jobs can be canceled via:
    `(r2.9) $ csctl cancel job wsjob-eyjapwgnycahq9tus4w7id`

Where the string after `wsjob-` is our job's unique ID, which is assigned and visible within our job logs or stdout.

See `csctl -h` for more options.

From here, our job will eventually work through its initialization, compile, and then execution phases! Note that we only need to compile the model once per experiment -- as long as the model implementation and batch sizes stay the same, the Wafer-Scale Cluster will cache and reuse our job's compilation plan. Also note that the compilation step does not "use up" a CS-3 -- another job can execute with no downside while the CS-3 services a separate compile job. Finally, because our jobs are scaled entirely through data parallelism, the compile plan for a given job can be handled using only a single CS-3 regardless of how many systems our actual job will run -- the same plan will be used for all systems.

# Useful Resources 

* [Cerebras Documntation](https://training-docs.cerebras.ai)
* [Cerebras Modelzoo Repo](https://github.com/Cerebras/modelzoo)
* Cluster Datasets Path: `/software/cerebras/dataset`
