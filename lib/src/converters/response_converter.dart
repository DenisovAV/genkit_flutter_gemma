import 'package:flutter_gemma/flutter_gemma.dart' as gemma;
import 'package:genkit/plugin.dart';

/// Converts a completed flutter_gemma response into a Genkit [ModelResponse].
///
/// Maps:
/// - Text → [ModelResponse] with [TextPart]
/// - Function call → [ModelResponse] with [ToolRequestPart]
ModelResponse convertFinalResponse(
  String fullText, {
  gemma.FunctionCallResponse? functionCall,
}) {
  final content = <Part>[];

  if (functionCall != null) {
    content.add(ToolRequestPart(
      toolRequest: ToolRequest(
        name: functionCall.name,
        input: functionCall.args,
      ),
    ));
  } else {
    content.add(TextPart(text: fullText));
  }

  return ModelResponse(
    finishReason: FinishReason.stop,
    message: Message(
      role: Role.model,
      content: content,
    ),
  );
}

/// Converts a streaming [gemma.ModelResponse] chunk to a Genkit [ModelResponseChunk].
///
/// Used with `context.sendChunk()` for streaming model output.
ModelResponseChunk convertStreamChunk(gemma.ModelResponse chunk) {
  final content = <Part>[];

  switch (chunk) {
    case gemma.TextResponse(:final token):
      content.add(TextPart(text: token));
    case gemma.FunctionCallResponse(:final name, :final args):
      content.add(ToolRequestPart(
        toolRequest: ToolRequest(name: name, input: args),
      ));
    case gemma.ThinkingResponse():
      // Skip thinking chunks — internal model reasoning.
      content.add(TextPart(text: ''));
  }

  return ModelResponseChunk(
    role: Role.model,
    content: content,
  );
}
