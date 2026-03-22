import 'package:schemantic/schemantic.dart';

part 'flutter_gemma_embed_options.g.dart';

/// Configuration options for flutter_gemma embedding generation.
@Schema(description: 'Configuration options for flutter_gemma embeddings')
abstract class $FlutterGemmaEmbedConfig {
  /// Preferred hardware backend hint ('cpu', 'gpu', 'npu').
  String? get preferredBackend;
}
