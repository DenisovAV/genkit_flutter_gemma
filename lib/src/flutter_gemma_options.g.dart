// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flutter_gemma_options.dart';

// **************************************************************************
// SchemaGenerator
// **************************************************************************

class FlutterGemmaModelOptions {
  FlutterGemmaModelOptions({
    this.maxTokens,
    this.temperature,
    this.topK,
    this.topP,
    this.supportImage,
    this.supportAudio,
    this.isThinking,
    this.randomSeed,
  });

  final int? maxTokens;
  final double? temperature;
  final int? topK;
  final double? topP;
  final bool? supportImage;
  final bool? supportAudio;
  final bool? isThinking;
  final int? randomSeed;

  static final $schema = _FlutterGemmaModelOptionsSchema();

  factory FlutterGemmaModelOptions.fromJson(Map<String, dynamic> json) {
    return FlutterGemmaModelOptions(
      maxTokens: json['maxTokens'] as int?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      topK: json['topK'] as int?,
      topP: (json['topP'] as num?)?.toDouble(),
      supportImage: json['supportImage'] as bool?,
      supportAudio: json['supportAudio'] as bool?,
      isThinking: json['isThinking'] as bool?,
      randomSeed: json['randomSeed'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (maxTokens != null) 'maxTokens': maxTokens,
      if (temperature != null) 'temperature': temperature,
      if (topK != null) 'topK': topK,
      if (topP != null) 'topP': topP,
      if (supportImage != null) 'supportImage': supportImage,
      if (supportAudio != null) 'supportAudio': supportAudio,
      if (isThinking != null) 'isThinking': isThinking,
      if (randomSeed != null) 'randomSeed': randomSeed,
    };
  }
}

class _FlutterGemmaModelOptionsSchema {
  Map<String, dynamic> jsonSchema() {
    return {
      'type': 'object',
      'description': 'Configuration options for flutter_gemma inference',
      'properties': {
        'maxTokens': {
          'type': 'integer',
          'description': 'Maximum number of tokens to generate. Defaults to 1024.',
        },
        'temperature': {
          'type': 'number',
          'description':
              'Sampling temperature. Higher values increase randomness. Defaults to 0.8.',
        },
        'topK': {
          'type': 'integer',
          'description': 'Top-K sampling parameter. Defaults to 1.',
        },
        'topP': {
          'type': 'number',
          'description': 'Top-P (nucleus) sampling parameter.',
        },
        'supportImage': {
          'type': 'boolean',
          'description': 'Whether the model supports image input (multimodal).',
        },
        'supportAudio': {
          'type': 'boolean',
          'description':
              'Whether the model supports audio input (Gemma 3n E4B).',
        },
        'isThinking': {
          'type': 'boolean',
          'description':
              'Whether to enable thinking mode (DeepSeek-style reasoning).',
        },
        'randomSeed': {
          'type': 'integer',
          'description': 'Random seed for deterministic output. Defaults to 1.',
        },
      },
    };
  }
}
