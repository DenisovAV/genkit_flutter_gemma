import 'package:flutter_gemma/flutter_gemma.dart' as gemma;
import 'package:genkit/plugin.dart';

import 'converters/request_converter.dart';
import 'converters/response_converter.dart';
import 'converters/tool_converter.dart';
import 'flutter_gemma_options.dart';
import 'flutter_gemma_runtime.dart';

/// Creates a Genkit [Model] action backed by flutter_gemma inference.
///
/// Each call to the model's `fn`:
/// 1. Extracts options from `request.config`
/// 2. Gets (or reuses cached) [gemma.InferenceModel] via [runtime]
/// 3. Creates an [gemma.InferenceChat] session
/// 4. Converts Genkit messages → flutter_gemma messages
/// 5. Generates response (streaming or non-streaming)
/// 6. Converts response back to Genkit format
Model createFlutterGemmaModel({
  required String name,
  required gemma.ModelType modelType,
  required gemma.ModelFileType fileType,
  required FlutterGemmaRuntime runtime,
}) {
  // Cache the inference model to avoid recreating on every call.
  gemma.InferenceModel? cachedModel;
  int? cachedMaxTokens;
  bool? cachedSupportImage;
  bool? cachedSupportAudio;

  return Model(
    name: name,
    fn: (request, context) async {
      if (request == null) {
        return ModelResponse(
          finishReason: FinishReason.stop,
          message: Message(
            role: Role.model,
            content: [TextPart(text: '')],
          ),
        );
      }

      // Parse config from the untyped Map.
      final configMap = request.config;
      final config = configMap != null
          ? FlutterGemmaModelOptions.fromJson(configMap)
          : null;

      final maxTokens = config?.maxTokens ?? 1024;
      final temperature = config?.temperature ?? 0.8;
      final topK = config?.topK ?? 1;
      final topP = config?.topP;
      final supportImage = config?.supportImage ?? false;
      final supportAudio = config?.supportAudio ?? false;
      final isThinking = config?.isThinking ?? false;

      // Get or create InferenceModel (cached if params match).
      final needsNewModel = cachedModel == null ||
          cachedMaxTokens != maxTokens ||
          cachedSupportImage != supportImage ||
          cachedSupportAudio != supportAudio;

      if (needsNewModel) {
        cachedModel = await runtime.getActiveModel(
          maxTokens: maxTokens,
          supportImage: supportImage,
          supportAudio: supportAudio,
        );
        cachedMaxTokens = maxTokens;
        cachedSupportImage = supportImage;
        cachedSupportAudio = supportAudio;
      }

      final model = cachedModel!;

      // Convert tools.
      final gemmaTools = convertTools(request.tools);
      final supportsFunctionCalls = gemmaTools.isNotEmpty;

      // Create chat session.
      final chat = await model.createChat(
        temperature: temperature,
        topK: topK,
        topP: topP,
        supportImage: supportImage,
        supportAudio: supportAudio,
        tools: gemmaTools,
        supportsFunctionCalls: supportsFunctionCalls,
        isThinking: isThinking,
        modelType: modelType,
      );

      // Convert and add messages.
      final gemmaMessages = await convertMessages(request.messages);
      for (final msg in gemmaMessages) {
        await chat.addQueryChunk(msg);
      }

      // Generate response.
      if (context.streamingRequested) {
        return _generateStreaming(chat, context.sendChunk);
      } else {
        return _generateBlocking(chat);
      }
    },
  );
}

/// Generates a blocking (non-streaming) response.
Future<ModelResponse> _generateBlocking(gemma.InferenceChat chat) async {
  final response = await chat.generateChatResponse();

  switch (response) {
    case gemma.TextResponse(:final token):
      return convertFinalResponse(token);
    case gemma.FunctionCallResponse(:final name, :final args):
      return convertFinalResponse(
        '',
        functionCall: gemma.FunctionCallResponse(name: name, args: args),
      );
    case gemma.ThinkingResponse(:final content):
      return convertFinalResponse(content);
  }
}

/// Generates a streaming response, sending chunks via [sendChunk].
Future<ModelResponse> _generateStreaming(
  gemma.InferenceChat chat,
  void Function(ModelResponseChunk) sendChunk,
) async {
  final fullText = StringBuffer();
  gemma.FunctionCallResponse? lastFunctionCall;

  await for (final chunk in chat.generateChatResponseAsync()) {
    sendChunk(convertStreamChunk(chunk));

    switch (chunk) {
      case gemma.TextResponse(:final token):
        fullText.write(token);
      case gemma.FunctionCallResponse(:final name, :final args):
        lastFunctionCall = gemma.FunctionCallResponse(name: name, args: args);
      case gemma.ThinkingResponse():
        break;
    }
  }

  return convertFinalResponse(
    fullText.toString(),
    functionCall: lastFunctionCall,
  );
}
