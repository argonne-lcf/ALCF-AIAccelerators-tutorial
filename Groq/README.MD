# Hands-on With Groq Systems 

Set up an account at Groq console: 
https://console.groq.com/home

Generate an API key 

```
export GROQ_API_KEY=<your-api-key-here>
pip install groq

```

Chat completion example with Python:
```
import os

from groq import Groq

client = Groq(
    api_key=os.environ.get("GROQ_API_KEY"),
)

chat_completion = client.chat.completions.create(
    messages=[
        {
            "role": "user",
            "content": "Explain the importance of fast language models",
        }
    ],
    model="llama-3.3-70b-versatile",
)

print(chat_completion.choices[0].message.content)
```
