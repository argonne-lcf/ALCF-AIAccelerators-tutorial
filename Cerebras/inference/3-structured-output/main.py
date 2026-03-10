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

movie_list_schema = {
    "type": "object",
    "properties": {
        "movies": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "title": {"type": "string"},
                    "director": {"type": "string"},
                    "year": {"type": "integer"},
                    "cast": {
                        "type": "array",
                        "items": {"type": "string"}
                    },
                    "synopsis": {"type": "string"},
                    "craft_and_performance_highlights": {"type": "string"},
                    "where_to_watch": {
                        "type": "array",
                        "items": {"type": "string"}
                    },
                },
                "required": ["title", "director", "year"],
                "additionalProperties": False
            }
        }
    },
    "required": ["movies"],
    "additionalProperties": False
}

# Initialize client
client = Cerebras(
    api_key=os.environ.get("CEREBRAS_API_KEY"),
)

# Ask for user input
user_input = input("User: ")

completion = client.chat.completions.create(
    model="gpt-oss-120b",
    messages=[
        {"role": "system", "content": "You are a helpful assistant that generates movie recommendations."},
        {"role": "user", "content": user_input}
    ],
    response_format={
        "type": "json_schema", 
        "json_schema": {
            "name": "movie_list_schema",
            "strict": True,
            "schema": movie_list_schema
        }
    }
)

# Parse the JSON response
movie_data = json.loads(completion.choices[0].message.content)
print(json.dumps(movie_data, indent=2).encode('utf-8').decode('utf-8'))
