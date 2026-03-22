import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_gemma/flutter_gemma.dart' as gemma;
import 'package:genkit/plugin.dart';
import 'package:http/http.dart' as http;

/// Converts Genkit [ModelRequest] messages to flutter_gemma [gemma.Message] list.
///
/// Key mapping rules:
/// - `Role.system` → Prepended to first user message text (flutter_gemma has no system role)
/// - `Role.user` → `Message(text: ..., isUser: true, imageBytes: ..., audioBytes: ...)`
/// - `Role.model` → `Message(text: ..., isUser: false)`
/// - `Role.tool` → `Message.toolResponse(toolName: ..., response: ...)`
///
/// Media resolution supports `data:` URIs, `file://` paths, absolute paths,
/// and `http://`/`https://` URLs (downloaded on the fly).
Future<List<gemma.Message>> convertMessages(
  List<Message> messages, {
  http.Client? httpClient,
}) async {
  final result = <gemma.Message>[];
  String? pendingSystemText;

  for (final message in messages) {
    final role = message.role;

    if (role == Role.system) {
      final text = _extractText(message.content);
      if (text.isNotEmpty) {
        pendingSystemText = (pendingSystemText != null)
            ? '$pendingSystemText\n$text'
            : text;
      }
    } else if (role == Role.user) {
      var text = _extractText(message.content);
      if (pendingSystemText != null) {
        text = '$pendingSystemText\n\n$text';
        pendingSystemText = null;
      }
      final imageBytes =
          await _extractMediaBytes(message.content, 'image', httpClient);
      final audioBytes =
          await _extractMediaBytes(message.content, 'audio', httpClient);

      if (imageBytes != null) {
        result.add(gemma.Message.withImage(
          text: text,
          imageBytes: imageBytes,
          isUser: true,
        ));
      } else if (audioBytes != null) {
        result.add(gemma.Message.withAudio(
          text: text,
          audioBytes: audioBytes,
          isUser: true,
        ));
      } else {
        result.add(gemma.Message(text: text, isUser: true));
      }
    } else if (role == Role.model) {
      final text = _extractText(message.content);
      final toolCallJson = _extractToolRequest(message.content);
      if (toolCallJson != null) {
        result.add(gemma.Message.toolCall(text: toolCallJson));
      } else {
        result.add(gemma.Message(text: text, isUser: false));
      }
    } else if (role == Role.tool) {
      final toolResponse = _extractToolResponse(message.content);
      if (toolResponse == null) {
        throw GenkitException(
          'Tool message contains no ToolResponsePart.',
          status: StatusCodes.INVALID_ARGUMENT,
        );
      }
      result.add(gemma.Message.toolResponse(
        toolName: toolResponse.toolName,
        response: toolResponse.response,
      ));
    }
  }

  // If system text was never consumed (no user message followed), add as user.
  if (pendingSystemText != null) {
    result.add(gemma.Message(text: pendingSystemText, isUser: true));
  }

  return result;
}

/// Extracts concatenated text from message content parts.
/// Uses [PartExtension.isText] and [PartExtension.text] for type discrimination.
String _extractText(List<Part> parts) {
  final buffer = StringBuffer();
  for (final part in parts) {
    if (part.isText) {
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write(part.text);
    }
  }
  return buffer.toString();
}

/// Extracts binary media data from content parts.
///
/// Supports:
/// - `data:` URI (base64) — decoded in-memory
/// - `file://` path — read from local filesystem
/// - Absolute path (`/...`) — read from local filesystem
/// - `http://` / `https://` URL — downloaded via HTTP GET
///
/// [mediaType] should be 'image' or 'audio'.
Future<Uint8List?> _extractMediaBytes(
  List<Part> parts,
  String mediaType,
  http.Client? httpClient,
) async {
  for (final part in parts) {
    if (part.isMedia) {
      final media = part.media!;
      final contentType = media.contentType ?? '';
      if (!contentType.startsWith(mediaType)) continue;

      final url = media.url;

      // data: URI (base64)
      if (url.startsWith('data:')) {
        final commaIndex = url.indexOf(',');
        if (commaIndex == -1) {
          throw GenkitException(
            'Malformed data: URI (missing comma separator)',
            status: StatusCodes.INVALID_ARGUMENT,
          );
        }
        try {
          return base64Decode(url.substring(commaIndex + 1));
        } on FormatException catch (e) {
          throw GenkitException(
            'Invalid base64 in media data URI: $e',
            status: StatusCodes.INVALID_ARGUMENT,
          );
        }
      }

      // file:// path
      if (url.startsWith('file://')) {
        final String path;
        try {
          path = Uri.parse(url).toFilePath();
        } on FormatException catch (e) {
          throw GenkitException(
            'Malformed file:// URI "$url": $e',
            status: StatusCodes.INVALID_ARGUMENT,
          );
        } on UnsupportedError catch (e) {
          throw GenkitException(
            'Unsupported file:// URI "$url": $e',
            status: StatusCodes.INVALID_ARGUMENT,
          );
        }
        return _readFileBytes(path);
      }

      // Absolute path (starts with /)
      if (url.startsWith('/')) {
        return _readFileBytes(url);
      }

      // HTTP/HTTPS URL — download
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final client = httpClient ?? http.Client();
        try {
          final response = await client.get(Uri.parse(url));
          if (response.statusCode == 200) {
            return response.bodyBytes;
          }
          throw GenkitException(
            'Failed to download media from $url: HTTP ${response.statusCode}',
            status: StatusCodes.INTERNAL,
          );
        } on GenkitException {
          rethrow;
        } catch (e) {
          throw GenkitException(
            'Failed to download media from $url: $e',
            status: StatusCodes.INTERNAL,
          );
        } finally {
          if (httpClient == null) client.close();
        }
      }

      // Unrecognized URL scheme — reject explicitly.
      throw GenkitException(
        'Unsupported media URL scheme: $url',
        status: StatusCodes.INVALID_ARGUMENT,
      );
    }
  }
  return null;
}

/// Extracts a tool request (function call) as JSON string from content parts.
String? _extractToolRequest(List<Part> parts) {
  for (final part in parts) {
    if (part.isToolRequest) {
      final toolReq = part.toolRequest!;
      final call = <String, dynamic>{
        'name': toolReq.name,
        'parameters': toolReq.input,
      };
      return jsonEncode(call);
    }
  }
  return null;
}

/// Extracts tool response data from content parts.
_ToolResponseData? _extractToolResponse(List<Part> parts) {
  for (final part in parts) {
    if (part.isToolResponse) {
      final toolResp = part.toolResponse!;
      final output = toolResp.output;
      return _ToolResponseData(
        toolName: toolResp.name,
        response: output is Map<String, dynamic>
            ? output
            : {'result': output},
      );
    }
  }
  return null;
}

/// Reads file bytes with error handling and context.
Future<Uint8List> _readFileBytes(String path) async {
  try {
    return await File(path).readAsBytes();
  } on FileSystemException catch (e) {
    final status = e.osError?.errorCode == 2 // ENOENT
        ? StatusCodes.NOT_FOUND
        : StatusCodes.INTERNAL;
    throw GenkitException(
      'Failed to read media file $path: $e',
      status: status,
    );
  }
}

class _ToolResponseData {
  const _ToolResponseData({required this.toolName, required this.response});
  final String toolName;
  final Map<String, dynamic> response;
}
