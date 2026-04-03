// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flutter_gemma_options.dart';

// **************************************************************************
// SchemaGenerator
// **************************************************************************

class FlutterGemmaModelOptions implements $FlutterGemmaModelOptions {
  FlutterGemmaModelOptions({
    this.maxTokens,
    this.temperature,
    this.topK,
    this.topP,
    this.supportImage,
    this.supportAudio,
    this.isThinking,
    this.randomSeed,
    this.toolChoice,
    this.systemInstruction,
  });

  @override
  final int? maxTokens;
  @override
  final double? temperature;
  @override
  final int? topK;
  @override
  final double? topP;
  @override
  final bool? supportImage;
  @override
  final bool? supportAudio;
  @override
  final bool? isThinking;
  @override
  final int? randomSeed;
  @override
  final String? toolChoice;
  @override
  final String? systemInstruction;

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
      toolChoice: json['toolChoice'] as String?,
      systemInstruction: json['systemInstruction'] as String?,
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
      if (toolChoice != null) 'toolChoice': toolChoice,
      if (systemInstruction != null) 'systemInstruction': systemInstruction,
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
        'toolChoice': {
          'type': 'string',
          'description':
              "Tool choice mode: 'auto', 'required', or 'none'. Defaults to 'auto'.",
          'enum': ['auto', 'required', 'none'],
        },
        'systemInstruction': {
          'type': 'string',
          'description':
              'System-level instruction passed natively to flutter_gemma. '
              'If set, takes priority over system-role messages in the request. '
              'If not set, system messages from the request are used.',
        },
      },
    };
  }
}
