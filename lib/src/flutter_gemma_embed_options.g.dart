// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flutter_gemma_embed_options.dart';

// **************************************************************************
// SchemaGenerator
// **************************************************************************

class FlutterGemmaEmbedConfig {
  FlutterGemmaEmbedConfig({this.preferredBackend});

  final String? preferredBackend;

  static final $schema = _FlutterGemmaEmbedConfigSchema();

  factory FlutterGemmaEmbedConfig.fromJson(Map<String, dynamic> json) {
    return FlutterGemmaEmbedConfig(
      preferredBackend: json['preferredBackend'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (preferredBackend != null) 'preferredBackend': preferredBackend,
    };
  }
}

class _FlutterGemmaEmbedConfigSchema {
  Map<String, dynamic> jsonSchema() {
    return {
      'type': 'object',
      'description': 'Configuration options for flutter_gemma embeddings',
      'properties': {
        'preferredBackend': {
          'type': 'string',
          'description': 'Preferred hardware backend hint (cpu, gpu).',
        },
      },
    };
  }
}
