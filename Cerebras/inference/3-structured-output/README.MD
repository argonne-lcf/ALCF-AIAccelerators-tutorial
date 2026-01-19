# Example 3: Structured Outputs

This example implements an AI agent which can use tools via function calling to complete tasks.

Structured outputs is a feature that can enforce consistent JSON outputs for models in the Cerebras
Inference API. This is particularly useful when building applications that need to process
AI-generated data programmatically. Some of the key benefits of using structured outputs are:

- Reduced Variability: Ensures consistent outputs by adhering to predefined fields.
- Type Safety: Enforces correct data types, preventing mismatches.
- Easier Parsing & Integration: Enables direct use in applications without extra processing.

In this example, we explore how to use structured outputs with the Cerebras Cloud SDK. We’ll build
a simple application that generates movie recommendations and uses structured outputs to ensure the
response is in a consistent JSON format.

0. **Prerequisites:**

   First setup your environment and API key as described [here](../README.MD).
   See [the previous example](../1-simple-chatbot/README.MD) for a basic introduction to the
   Cerebras inference API.

1. **Defining the Response Schema:**

   To ensure structured responses from the model, we’ll use a JSON schema to define our output
   structure. Start by defining your schema, which specifies the fields, their types, and which
   ones are required. For our example, we’ll define a schema for a movie recommendation that
   includes the title, director, and year:

   ```
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
   ```

2. **Using Structured Outputs:**

   Next, use the schema in your API call by setting the `response_format` parameter to include both
   the type and your schema. Setting `strict` to `true` will enforce the schema. Setting `strict`
   to `false` will allow the model to return additional fields that are not specified in the
   schema.

   ```
   completion = client.chat.completions.create(
       model="llama-4-scout-17b-16e-instruct",
       messages=[
           {"role": "system", "content": "You are a helpful assistant that generates movie recommendations."},
           {"role": "user", "content": "Suggest a sci-fi movie from the 1990s"}
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
   ```

3. **More Complex Schemas:**

   Your schema can include various JSON Schema features, such as fundamental data types, nested
   structures, required fields, and enums. For example, a more complex schema might look like:

   ```
   detailed_schema = {
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
   ```

   Try replacing the JSON schema in the example with the more complex JSON schema above and
   compare responses.
   
