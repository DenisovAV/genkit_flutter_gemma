import 'package:schemantic/schemantic.dart';

part 'flutter_gemma_options.g.dart';

/// Configuration options for flutter_gemma model inference.
///
/// These options map to flutter_gemma's `createChat` and `getActiveModel`
/// parameters.
@Schema(description: 'Configuration options for flutter_gemma inference')
abstract class $FlutterGemmaModelOptions {
  /// Maximum number of tokens to generate. Defaults to 1024.
  int? get maxTokens;

  /// Sampling temperature. Higher values increase randomness. Defaults to 0.8.
  double? get temperature;

  /// Top-K sampling parameter. Defaults to 1.
  int? get topK;

  /// Top-P (nucleus) sampling parameter.
  double? get topP;

  /// Whether the model supports image input (multimodal).
  bool? get supportImage;

  /// Whether the model supports audio input (Gemma 3n E4B).
  bool? get supportAudio;

  /// Whether to enable thinking mode (DeepSeek-style reasoning).
  bool? get isThinking;

  /// Random seed for deterministic output. Defaults to 1.
  int? get randomSeed;

  /// Tool choice mode: 'auto', 'required', or 'none'. Defaults to 'auto'.
  String? get toolChoice;
}
