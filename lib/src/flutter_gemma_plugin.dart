import 'package:flutter_gemma/flutter_gemma.dart' as gemma;
import 'package:genkit/plugin.dart';

import 'flutter_gemma_embed_options.dart';
import 'flutter_gemma_embedder.dart';
import 'flutter_gemma_model.dart';
import 'flutter_gemma_options.dart';
import 'flutter_gemma_runtime.dart';

/// Configuration for a single model exposed by [GenkitFlutterGemmaPlugin].
class FlutterGemmaModelConfig {
  FlutterGemmaModelConfig({
    required this.name,
    required this.modelType,
    this.fileType = gemma.ModelFileType.task,
  }) {
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Model name must not be empty');
    }
  }

  /// Display name for this model (e.g. 'gemma-3-nano').
  /// Registered as 'flutter-gemma/<name>' in Genkit.
  final String name;

  /// The flutter_gemma model architecture type.
  final gemma.ModelType modelType;

  /// The model file format (.task or .binary).
  final gemma.ModelFileType fileType;
}

/// Configuration for an embedder exposed by [GenkitFlutterGemmaPlugin].
class FlutterGemmaEmbedderConfig {
  FlutterGemmaEmbedderConfig({required this.name}) {
    if (name.isEmpty) {
      throw ArgumentError.value(
          name, 'name', 'Embedder name must not be empty');
    }
  }

  /// Display name for this embedder (e.g. 'embedding-gemma-300m').
  /// Registered as 'flutter-gemma/<name>' in Genkit.
  final String name;
}

/// Genkit plugin that bridges flutter_gemma for on-device AI inference
/// and embedding generation.
///
/// Usage:
/// ```dart
/// final ai = Genkit(plugins: [
///   GenkitFlutterGemmaPlugin(
///     models: [
///       FlutterGemmaModelConfig(
///         name: 'gemma-3-nano',
///         modelType: ModelType.gemmaIt,
///       ),
///     ],
///     embedders: [
///       FlutterGemmaEmbedderConfig(name: 'embedding-gemma-300m'),
///     ],
///   ),
/// ]);
///
/// final response = await ai.generate(
///   model: flutterGemma.model('gemma-3-nano'),
///   prompt: 'Hello!',
/// );
/// ```
///
/// **Important**: The host app is responsible for installing models via
/// `FlutterGemma.installModel()` / `FlutterGemma.installEmbedder()`.
class GenkitFlutterGemmaPlugin extends GenkitPlugin {
  GenkitFlutterGemmaPlugin({
    required List<FlutterGemmaModelConfig> models,
    List<FlutterGemmaEmbedderConfig> embedders = const [],
    FlutterGemmaRuntime? runtime,
  })  : models = List.unmodifiable(models),
        embedders = List.unmodifiable(embedders),
        runtime = runtime ?? const DefaultFlutterGemmaRuntime() {
    // Validate name uniqueness.
    final modelNames = models.map((c) => c.name).toSet();
    if (modelNames.length != models.length) {
      throw ArgumentError('Duplicate model names in configuration');
    }
    final embedderNames = embedders.map((c) => c.name).toSet();
    if (embedderNames.length != embedders.length) {
      throw ArgumentError('Duplicate embedder names in configuration');
    }
  }

  static const prefix = 'flutter-gemma';

  /// List of model configurations this plugin exposes.
  final List<FlutterGemmaModelConfig> models;

  /// List of embedder configurations this plugin exposes.
  final List<FlutterGemmaEmbedderConfig> embedders;

  /// Runtime used to obtain inference and embedding models.
  final FlutterGemmaRuntime runtime;

  /// Cache for resolved actions to avoid recreating on every resolve() call.
  final Map<String, Action> _resolvedActions = {};

  @override
  String get name => prefix;

  @override
  Future<List<ActionMetadata>> list() async {
    final metadata = <ActionMetadata>[];

    for (final config in models) {
      metadata.add(ActionMetadata(
        actionType: 'model',
        name: '$prefix/${config.name}',
        metadata: {
          'model': {
            'label': config.name,
            'customOptions':
                FlutterGemmaModelOptions.$schema.jsonSchema(),
            'supports': {
              'multiturn': true,
              'media': true,
              'tools': true,
              'systemRole': false,
              'output': ['text'],
            },
          },
        },
      ));
    }

    for (final config in embedders) {
      metadata.add(ActionMetadata(
        actionType: 'embedder',
        name: '$prefix/${config.name}',
        metadata: {
          'embedder': {
            'label': config.name,
            'customOptions':
                FlutterGemmaEmbedConfig.$schema.jsonSchema(),
          },
        },
      ));
    }

    return metadata;
  }

  @override
  Action? resolve(String actionType, String name) {
    final cacheKey = '$actionType:$name';
    final cached = _resolvedActions[cacheKey];
    if (cached != null) return cached;

    if (actionType == 'model') {
      final config = models
          .where((c) => '$prefix/${c.name}' == name)
          .firstOrNull;
      if (config == null) return null;

      final action = createFlutterGemmaModel(
        name: name,
        modelType: config.modelType,
        fileType: config.fileType,
        runtime: runtime,
      );
      _resolvedActions[cacheKey] = action;
      return action;
    }

    if (actionType == 'embedder') {
      final config = embedders
          .where((c) => '$prefix/${c.name}' == name)
          .firstOrNull;
      if (config == null) return null;

      final action = createFlutterGemmaEmbedder(
        name: name,
        runtime: runtime,
      );
      _resolvedActions[cacheKey] = action;
      return action;
    }

    return null;
  }
}
