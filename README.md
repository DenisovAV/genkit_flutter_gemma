# genkit_flutter_gemma

Genkit Dart plugin for [flutter_gemma](https://pub.dev/packages/flutter_gemma) — local on-device AI inference via Google Gemma and other supported models.

## Features

- Wraps `flutter_gemma` as a Genkit model provider
- Supports text generation (blocking and streaming)
- Embeddings via `FlutterGemmaEmbedder`
- Multimodal input (images, audio) — supports `data:` URIs, `file://` paths, and `http(s)://` URLs
- Function calling / tool use
- Thinking mode (DeepSeek-style reasoning)
- Configurable via `@Schema()`-annotated options

## Supported Model Architectures

| Architecture | ModelType | Notes |
|---|---|---|
| Gemma IT | `ModelType.gemmaIt` | Default, multimodal support |
| DeepSeek | `ModelType.deepSeek` | Thinking mode |
| Qwen | `ModelType.qwen` | |
| Llama | `ModelType.llama` | |
| FunctionGemma | `ModelType.functionGemma` | Specialized function calling |

## Quick Start

```dart
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:genkit/genkit.dart';
import 'package:genkit_flutter_gemma/genkit_flutter_gemma.dart';

// Initialize and install model (host app responsibility)
await FlutterGemma.initialize();
await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
    .fromAsset('assets/gemma-3-1b-it-int4.task')
    .install();

// Create Genkit with plugin
final ai = Genkit(plugins: [
  GenkitFlutterGemmaPlugin(
    models: [
      FlutterGemmaModelConfig(
        name: 'gemma-3-nano',
        modelType: ModelType.gemmaIt,
      ),
    ],
    embedders: [
      FlutterGemmaEmbedderConfig(name: 'embedding-gemma-300m'),
    ],
  ),
]);

// Generate
final response = await ai.generate(
  model: flutterGemma.model('gemma-3-nano'),
  prompt: 'Hello!',
);
print(response.text);
```

## Configuration

Pass `FlutterGemmaModelOptions` to customize inference:

```dart
final response = await ai.generate(
  model: flutterGemma.model('gemma-3-nano'),
  prompt: 'Hello!',
  config: FlutterGemmaModelOptions(
    maxTokens: 2048,
    temperature: 0.5,
    topK: 40,
    supportImage: true,
  ),
);
```

| Option | Type | Default | Description |
|---|---|---|---|
| `maxTokens` | `int?` | 1024 | Maximum tokens to generate |
| `temperature` | `double?` | 0.8 | Sampling temperature |
| `topK` | `int?` | 1 | Top-K sampling |
| `topP` | `double?` | null | Top-P (nucleus) sampling |
| `supportImage` | `bool?` | false | Enable multimodal image input |
| `supportAudio` | `bool?` | false | Enable audio input (Gemma 3n) |
| `isThinking` | `bool?` | false | Enable thinking mode |

## Streaming

```dart
final stream = ai.generateStream(
  model: flutterGemma.model('gemma-3-nano'),
  prompt: 'Write a story.',
);

await for (final chunk in stream) {
  stdout.write(chunk.text);
}
```

## Tool Use

```dart
final response = await ai.generate(
  model: flutterGemma.model('gemma-3-nano'),
  prompt: 'What is the weather in Paris?',
  tools: [weatherTool],
);
```

## Embeddings

```dart
// Install embedding model + tokenizer (host app responsibility)
await FlutterGemma.installEmbedder()
    .modelFromNetwork('https://huggingface.co/.../embeddinggemma-300M.tflite')
    .tokenizerFromNetwork('https://huggingface.co/.../sentencepiece.model')
    .install();

// Generate embeddings
final embeddings = await ai.embed(
  embedder: flutterGemma.embedder('embedding-gemma-300m'),
  documents: [
    DocumentData(content: [TextPart(text: 'Flutter is a UI toolkit.')]),
    DocumentData(content: [TextPart(text: 'Dart is a programming language.')]),
  ],
);

for (final embedding in embeddings) {
  print('Vector (${embedding.embedding.length} dims): '
      '${embedding.embedding.take(5)}...');
}
```

## Known Limitations

- **Model installation**: The plugin does NOT manage model installation. The host app must install models via `FlutterGemma.installModel()` and embedders via `FlutterGemma.installEmbedder()` before using the plugin.
- **System role**: flutter_gemma doesn't support a native system role. System messages are prepended to the first user message.
