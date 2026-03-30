import 'package:flutter_gemma/flutter_gemma.dart' as gemma;
import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/plugin.dart';
import 'package:genkit_flutter_gemma/src/flutter_gemma_model.dart';

import 'src/fake_runtime.dart';

void main() {
  late FakeRuntime runtime;
  late FakeInferenceChat fakeChat;
  late FakeInferenceModel fakeModel;

  setUp(() {
    fakeChat = FakeInferenceChat();
    fakeModel = FakeInferenceModel()..chatToReturn = fakeChat;
    runtime = FakeRuntime(model: fakeModel);
  });

  Model buildModel() {
    return createFlutterGemmaModel(
      name: 'flutter-gemma/test-model',
      modelType: gemma.ModelType.gemmaIt,
      fileType: gemma.ModelFileType.task,
      runtime: runtime,
    );
  }

  ModelRequest simpleRequest([String text = 'Hello']) {
    return ModelRequest(
      messages: [
        Message(
          role: Role.user,
          content: [TextPart(text: text)],
        ),
      ],
    );
  }

  group('createFlutterGemmaModel', () {
    test('blocking: returns text response', () async {
      fakeChat.blockingResponse = const gemma.TextResponse('Hello back!');

      final model = buildModel();
      final response = await model(simpleRequest());

      expect(response.message!.content.first.isText, isTrue);
      expect(response.message!.content.first.text, 'Hello back!');
      expect(response.finishReason, FinishReason.stop);
    });

    test('blocking: returns function call response', () async {
      fakeChat.blockingResponse = const gemma.FunctionCallResponse(
        name: 'get_weather',
        args: {'city': 'Moscow'},
      );

      final model = buildModel();
      final response = await model(simpleRequest());

      expect(response.message!.content.first.isToolRequest, isTrue);
      final toolReq = response.message!.content.first.toolRequest!;
      expect(toolReq.name, 'get_weather');
      expect(toolReq.input, {'city': 'Moscow'});
    });

    test('streaming: sends chunks and returns final response', () async {
      fakeChat.streamingResponses = [
        const gemma.TextResponse('Hello '),
        const gemma.TextResponse('world!'),
      ];

      final model = buildModel();
      final chunks = <ModelResponseChunk>[];

      final response = await model(
        simpleRequest(),
        onChunk: chunks.add,
      );

      expect(chunks, hasLength(2));
      expect(chunks[0].content.first.isText, isTrue);
      expect(chunks[0].content.first.text, 'Hello ');
      expect(chunks[1].content.first.text, 'world!');
      expect(response.message!.content.first.text, 'Hello world!');
    });

    test('streaming: handles function call in stream', () async {
      fakeChat.streamingResponses = [
        const gemma.FunctionCallResponse(
          name: 'search',
          args: {'q': 'dart'},
        ),
      ];

      final model = buildModel();
      final chunks = <ModelResponseChunk>[];

      final response = await model(
        simpleRequest(),
        onChunk: chunks.add,
      );

      expect(response.message!.content.first.isToolRequest, isTrue);
      expect(response.message!.content.first.toolRequest!.name, 'search');
    });

    test('caches model when config is unchanged', () async {
      fakeChat.blockingResponse = const gemma.TextResponse('ok');
      final model = buildModel();

      await model(simpleRequest('first'));
      await model(simpleRequest('second'));

      expect(runtime.getActiveModelCallCount, 1);
      expect(fakeModel.createChatCallCount, 2);
    });

    test('recreates model when config changes', () async {
      fakeChat.blockingResponse = const gemma.TextResponse('ok');
      final model = buildModel();

      // First call with default config.
      await model(simpleRequest());

      // Second call with different maxTokens.
      final request = ModelRequest(
        messages: [
          Message(
            role: Role.user,
            content: [TextPart(text: 'Hi')],
          ),
        ],
        config: {'maxTokens': 2048},
      );
      await model(request);

      expect(runtime.getActiveModelCallCount, 2);
    });

    test('converts messages and passes to chat', () async {
      fakeChat.blockingResponse = const gemma.TextResponse('ok');

      final model = buildModel();
      await model(
        ModelRequest(
          messages: [
            Message(
              role: Role.user,
              content: [TextPart(text: 'Hello')],
            ),
            Message(
              role: Role.model,
              content: [TextPart(text: 'Hi')],
            ),
            Message(
              role: Role.user,
              content: [TextPart(text: 'How are you?')],
            ),
          ],
        ),
      );

      expect(fakeChat.addQueryChunkCallCount, 3);
      expect(fakeChat.receivedMessages[0].text, 'Hello');
      expect(fakeChat.receivedMessages[0].isUser, isTrue);
      expect(fakeChat.receivedMessages[1].text, 'Hi');
      expect(fakeChat.receivedMessages[1].isUser, isFalse);
      expect(fakeChat.receivedMessages[2].text, 'How are you?');
    });

    test('passes toolChoice required to createChat', () async {
      fakeChat.blockingResponse = const gemma.TextResponse('ok');
      final model = buildModel();

      await model(ModelRequest(
        messages: [
          Message(role: Role.user, content: [TextPart(text: 'Hi')]),
        ],
        config: {'toolChoice': 'required'},
      ));

      expect(fakeModel.lastToolChoice, gemma.ToolChoice.required);
    });

    test('passes toolChoice none to createChat', () async {
      fakeChat.blockingResponse = const gemma.TextResponse('ok');
      final model = buildModel();

      await model(ModelRequest(
        messages: [
          Message(role: Role.user, content: [TextPart(text: 'Hi')]),
        ],
        config: {'toolChoice': 'none'},
      ));

      expect(fakeModel.lastToolChoice, gemma.ToolChoice.none);
    });

    test('defaults toolChoice to auto', () async {
      fakeChat.blockingResponse = const gemma.TextResponse('ok');
      final model = buildModel();

      await model(simpleRequest());

      expect(fakeModel.lastToolChoice, gemma.ToolChoice.auto);
    });

    test('blocking: returns parallel function call response', () async {
      fakeChat.blockingResponse = const gemma.ParallelFunctionCallResponse(
        calls: [
          gemma.FunctionCallResponse(name: 'get_weather', args: {'city': 'Moscow'}),
          gemma.FunctionCallResponse(name: 'get_time', args: {'tz': 'MSK'}),
        ],
      );

      final model = buildModel();
      final response = await model(simpleRequest());

      final parts = response.message!.content;
      expect(parts, hasLength(2));
      expect(parts[0].isToolRequest, isTrue);
      expect(parts[0].toolRequest!.name, 'get_weather');
      expect(parts[1].isToolRequest, isTrue);
      expect(parts[1].toolRequest!.name, 'get_time');
    });

    test('streaming: accumulates parallel function calls', () async {
      fakeChat.streamingResponses = [
        const gemma.TextResponse('thinking... '),
        const gemma.ParallelFunctionCallResponse(
          calls: [
            gemma.FunctionCallResponse(name: 'a', args: {'x': 1}),
            gemma.FunctionCallResponse(name: 'b', args: {'y': 2}),
          ],
        ),
      ];

      final model = buildModel();
      final chunks = <ModelResponseChunk>[];

      final response = await model(
        simpleRequest(),
        onChunk: chunks.add,
      );

      expect(chunks, hasLength(2));
      final parts = response.message!.content;
      expect(parts.where((p) => p.isToolRequest).length, 2);
    });

    test('null request throws GenkitException', () async {
      final model = buildModel();

      await expectLater(
        model(null),
        throwsA(isA<GenkitException>()),
      );
    });
  });
}
