import os
import json
from pydantic import BaseModel, Field
from cerebras.cloud.sdk import Cerebras

movie_schema = {
    "type": "object",
    "properties": {
        "title": {"type": "string"},
        "director": {"type": "string"},
        "year": {"type": "integer"},
    },
    "required": ["title", "director", "year"],
    "additionalProperties": False
}

detailed_movie_schema = {
    "type": "object",
    "properties": {
        "title": {"type": "string"},
        "director": {"type": "string"},
        "year": {"type": "integer"},
        "genres": {
            "type": "array",
            "items": {"type": "string"}
        },
        "rating": {
            "type": "string",
            "enum": ["G", "PG", "PG‑13", "R"]
        },
        "cast": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "name": {"type": "string"},
                    "role": {"type": "string"}
                },
                "required": ["name"],
                "additionalProperties": False
            }
        }
    },
    "required": ["title", "director", "year", "genres"],
    "additionalProperties": False
}

# Initialize client
client = Cerebras(
    api_key=os.environ.get("CEREBRAS_API_KEY"),
)

# Ask for user input
user_input = input("User: ")

completion = client.chat.completions.create(
    model="qwen-3-32b",
    messages=[
        {"role": "system", "content": "You are a helpful assistant that generates movie recommendations."},
        {"role": "user", "content": user_input}
    ],
    response_format={
        "type": "json_schema", 
        "json_schema": {
            "name": "movie_schema",
            "strict": True,
            "schema": movie_schema
        }
    }
)

# Parse the JSON response
movie_data = json.loads(completion.choices[0].message.content)
print(json.dumps(movie_data, indent=2))
