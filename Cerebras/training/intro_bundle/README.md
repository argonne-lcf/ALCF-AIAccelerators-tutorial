Welcome! This bundle exists to help get your feet under you and to streamline
some of the basic operations you need to get started using a Cerebras
Wafer-Scale Cluster.

The bundle is organized into a number of directories, arranged in the sequence
I recommend you executing and reading through them, both to build upon one
another in terms of technical dependencies (you need data to train a model),
but also to cover the most important information first. The directory names
themselves are relatively self-explanatory. Each directory also contains a
`run.sh` script to execute its core functionality, and a `cleanup.sh` script
to tidy up things like checkpoint directories, datasets, etc in order to keep
things lightweight.

Where possible, I've included examples covering both natural language models
and multimodal vision-text models commonly used for visual-question answering
(VQA). Many of the points you learn from natural language workflows will
transfer across modalities, but the multimodal examples can help to understand
which things change from data modality to data modality.

In order to use this bundle, run `cp -r /n0/cerebras/training_intro_bundle/ </path/to/my/dir>`,
where the destination directory lies inside your project directory. Project
directories always have the path format `/cra-xxx/`, where xxx is a particular
project ID. If you do not know your project ID, you can reach out to me for
info or try to `cd /cra-xxx/` -- you'll only have permissions to enter if it's
been assigned to your account. Once the bundle has been copied, feel free to
edit and experiment with it as you please.

If you have any questions or run into issues, please don't hesitate to reach
out to me at sylvia.howland@cerebras.net.
