Welcome! This bundle exists to help get your feet under you and to streamline
some of the basic operations you need to get started using a Cerebras
Wafer-Scale Cluster at ALCF.

The bundle is organized into a number of directories, arranged in the sequence
I recommend you executing and reading through them, both to build upon one
another in terms of technical dependencies (you need data to train a model),
but also to cover the most important information first. The directory names
themselves are relatively self-explanatory. Stages `2_`, `3_` and `4_` each
contain a `run.sh` script to execute their core functionality, and a
`cleanup.sh` script to tidy up things like checkpoint directories and
datasets in order to keep things lightweight. Stage `1_env_setup` instead has
`setup_env.sh` and `cleanup_env.sh`, which you `source` rather than run.

Where possible, I've included examples covering both natural language models
and multimodal vision-text models commonly used for visual-question answering
(VQA). Many of the points you learn from natural language workflows will
transfer across modalities, but the multimodal examples can help to understand
which things change from data modality to data modality.


GETTING STARTED
---------------

1. Copy the bundle somewhere you can write to, and work in the copy:

       cp -r /software/cerebras/training_bundle/training_intro_bundle_sc26 ~/training_intro_bundle
       cd ~/training_intro_bundle

   The copy is not optional. Stages 2, 3 and 4 write their output *into* the
   bundle -- generated datasets, checkpoints, model directories -- and the
   shared copy is read-only.

2. Set up the environment. Use `source`, not `sh`, so that the virtual
   environment is still active when it finishes:

       source 1_env_setup/setup_env.sh

   This builds a Python 3.11 virtual environment at `venvs/r2.10` inside the
   bundle, installs modelzoo 2.10, sets the ALCF HTTP proxy, and confirms the
   client stack can reach the appliance. Set `CSBUNDLE_VENV` beforehand if you
   want the virtual environment somewhere else.

   It also runs `configure_paths.sh`, which fills in the `__BUNDLE_ROOT__`
   placeholder in the training configs so they point at your copy. If you ever
   move the bundle, just run `./configure_paths.sh` again. To see what the
   configs currently point at, run `./configure_paths.sh --check`.

3. Work through `2_data_processing`, `3_training` and `4_checkpoint_conversion`
   in order. To re-activate the environment in a later session:

       source ~/training_intro_bundle/venvs/r2.10/bin/activate


A NOTE ON RUN LENGTH
--------------------

Every training config here ships with `max_steps: 10` so that a first run
finishes quickly and hands the wafer back. This is a tutorial default, not a
meaningful amount of training. Each config records the author's original
value in a comment next to the setting -- 12,000 steps for the two Llama
configs, 238,418 for Mixtral -- so you can restore it when you want to run
something real.

Note also that "tiny" in `llama3_tiny_msl_2k` means two layers, not a small
model: it is full Llama-3-8B width (hidden size 4096, 32 heads). None of
these are cheap per step. The cluster is shared, so raise `max_steps` only
when you actually intend a long run.

What that costs in practice, measured on this cluster with
`llama3_tiny_msl_2k.yaml` at its shipped settings:

    whole 10-step run, cold          ~19 minutes
      of which: 10 training steps      ~1 second
      of which: writing one checkpoint ~2 minutes
      the remaining ~16 minutes is queue wait, compile and appliance
      staging, which the client log does not separate
    steady throughput                 ~75 samples/sec at batch size 16
    one checkpoint on disk            ~17.9 GB

Two things follow. Compilation and setup dominate a short run, so re-running
the same config is far quicker -- the compile is cached and reused. And
checkpoints are large: the author's original `checkpoint.steps: 100` over
12,000 steps would write about 120 of them, so raise `max_steps` and
`checkpoint.steps` together.

Note that `run.sh` writes `out.log` in its own directory and overwrites it
each run. Copy it elsewhere if you want to keep a record.

A NOTE ON DATA AND TOKENIZERS
-----------------------------

Stage 3 trains on the HDF5 that stage 2 produces, so run stage 2 first. The
two must agree on a tokenizer: the training configs declare
`vocab_size: 128256`, which is the Llama-3 vocabulary, and the stage-2
preprocessing configs use a local copy of the Llama-3 tokenizer at
`/software/cerebras/acceptance_tests_2025/inference/Meta-Llama-3.1-8B-Instruct`.
Using a local copy means this step needs no HuggingFace credential.

If you point a config at a different dataset, check its tokenizer. The site
holds a number of pre-tokenized corpora under `/software/cerebras/dataset/`,
and they are not interchangeable. In particular **the SlimPajama HDF5 there is
GPT-2 tokenized** (vocabulary 50257). Feeding it to one of these Llama-3
configs will not raise an error -- every token id is a valid Llama-3 id -- it
will simply train on nonsense. Use a `vocab_size: 50257` config for it.

The multimodal example is the exception to "run stage 2 first": it reads a
prepared LLaVA synthdog-en dataset directly from
`/software/cerebras/dataset/llava/`, so it works without any preprocessing.


If you have any questions or run into issues, please don't hesitate to reach
out to me at sylvia.howland@cerebras.net.
