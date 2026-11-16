# Getting Started with Cerebras Inference

## Step 1: Prerequisites

To complete setup, you will need:

- A Cerebras account
- A Cerebras Inference API key
- Python 3.7+

Visit [our Cloud platform here](https://cloud.cerebras.ai) to sign up for an account and create an
API key by navigating to "API Keys" on the left nav bar.


## Step 2: Setting up Your Environment

Set your API key as an environment variable. You can do this by running the following command in
your terminal:

```
export CEREBRAS_API_KEY="your-api-key-here"
```

Now create a Python virtual environment for installing relevant packages, for instance:

```
python -m venv ~/venvs/cb-inference
```

This directory includes a `requirements.txt` file with relevant packages to install into your
environment, including the Cerebras Inference library package `cerebras_cloud_sdk`. Activate your
environment and install the packages:

```
source ~/venvs/cb-inference/bin/activate
pip install -r requirements.txt
```

If you have already set up the training bundle, activate `~/venvs/cb-tutorial` instead and
skip both steps — `cerebras_cloud_sdk` is a dependency of the modelzoo, so it is already there.

## Step 3: Run Inference

On the public tier, chat completions are served by:

 | Model Name		| Model ID		| Parameters
 | -------------------- | --------------------- | ------------
 | OpenAI GPT OSS	| `gpt-oss-120b`	| 120 billion
 | Qwen 3 27B		| `qwen-3.8-27b`	| 27 billion

Every example in this directory uses `gpt-oss-120b`. For the current catalogue, see the
[Cerebras Inference model documentation](https://inference-docs.cerebras.ai/introduction).

Try a simple chat completion with `OpenAI GPT OSS` by running the below Python code snippet,
which can be found in `test.py` in this directory:

```
import os
from cerebras.cloud.sdk import Cerebras

client = Cerebras(
    # This is the default and can be omitted
    api_key=os.environ.get("CEREBRAS_API_KEY"),
)

chat_completion = client.chat.completions.create(
    messages=[
        {
            "role": "user",
            "content": "Why is fast inference important?",
        }
],
    model="gpt-oss-120b",
)

print(chat_completion.model_dump_json(indent=2))
```

Now you're ready to run the examples. This directory includes three examples:
- [one demonstrating a simple chatbot application](1-simple-chatbot/README.MD),
- [one demonstrating function calling](2-function-calling/README.MD), and
- [one demonstrating structured output](3-structured-output/README.MD).

## More Information

For more information, visit our
[Cerebras Inference documentation](https://inference-docs.cerebras.ai/introduction).
