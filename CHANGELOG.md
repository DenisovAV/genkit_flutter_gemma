## 0.2.1

- Bump flutter_gemma dependency to ^0.13.1 (LiteRT-LM 0.10.0, Gemma 4 thinking mode fix)

## 0.2.0

- **Breaking**: Upgrade flutter_gemma dependency to ^0.13.0
- **Breaking**: System messages are now passed natively via `createChat(systemInstruction:)` instead of being prepended to the first user message
- Add `systemInstruction` config option for explicit system-level instructions
- Support `ModelFileType.litertlm` for LiteRT-LM models (Gemma 4)
- Advertise `systemRole: true` in Genkit model metadata
- Throw on system-only requests (at least one user/model message required)
- Throw on system messages with non-text content parts

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
