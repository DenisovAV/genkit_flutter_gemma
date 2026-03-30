## 0.1.1

- Bump flutter_gemma dependency to ^0.12.8
- Add `toolChoice` config option ('auto', 'required', 'none') passed to model chat session
- Support `ParallelFunctionCallResponse` — multiple tool calls in a single model response
- Add `latencyMs` to ModelResponse for generation profiling
- Fix `FakeEmbeddingModel` compatibility with flutter_gemma 0.12.8 `taskType` parameter

## 0.1.0

- Initial release
- Genkit model provider wrapping flutter_gemma
- Text generation (blocking and streaming)
- Embeddings via FlutterGemmaEmbedder
- Multimodal input (images, audio)
- Function calling / tool use
- Thinking mode (DeepSeek-style reasoning)
- Configurable via `@Schema()`-annotated options
- Example app with Chat, Embeddings, Tools, Settings tabs
