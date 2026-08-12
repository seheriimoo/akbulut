import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'vendor_provider.dart';

/// OpenAI chat-completions transport adapter.
///
/// Implements [VendorProvider] only: serializes one sealed [VendorRequest],
/// performs one non-streaming HTTP completion, returns one [VendorResponse]
/// or throws [VendorError].
///
/// Transport serialization uses [VendorRequest.compiled] only — no ad-hoc
/// cognitive prompt invention. Owns no WHAT, release, protocol, exit, DNA
/// enforcement, retries, timeout policy, fallback, or Conversation emission.
/// When [VendorRequest.timeout] is present, enforces that client-supplied
/// limit on the wire only. Config (API key / model) stays outside cognitive
/// ownership and NightSession.
class OpenAIVendorProvider implements VendorProvider {
  static const String defaultModel = 'gpt-4o-mini';
  static final Uri defaultEndpoint =
      Uri.parse('https://api.openai.com/v1/chat/completions');

  final String apiKey;
  final String model;
  final Uri endpoint;
  final http.Client _client;

  OpenAIVendorProvider({
    required this.apiKey,
    this.model = defaultModel,
    Uri? endpoint,
    http.Client? client,
  })  : endpoint = endpoint ?? defaultEndpoint,
        _client = client ?? http.Client();

  /// Loads provider auth/config from env. Not a cognitive path.
  factory OpenAIVendorProvider.fromEnv({
    String model = defaultModel,
    Uri? endpoint,
    http.Client? client,
  }) {
    return OpenAIVendorProvider(
      apiKey: _readApiKey(),
      model: model,
      endpoint: endpoint,
      client: client,
    );
  }

  static String _readApiKey() {
    try {
      return dotenv.env['OPENAI_API_KEY'] ?? '';
    } catch (_) {
      // Dotenv may be unloaded in tests / early bootstrap; auth fails at call.
      return '';
    }
  }

  @override
  Future<VendorResponse> complete(VendorRequest request) async {
    if (apiKey.trim().isEmpty) {
      throw const VendorError(
        kind: VendorErrorKind.auth,
        message: 'OpenAI API key is missing',
      );
    }

    final http.Response response;
    try {
      final post = _client.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(_serialize(request)),
      );

      // Wire enforcement only — timeout policy remains on LanguageModelClient.
      final limit = request.timeout;
      response = limit == null ? await post : await post.timeout(limit);
    } on TimeoutException {
      throw const VendorError(
        kind: VendorErrorKind.timeout,
        message: 'OpenAI request exceeded client-supplied VendorRequest.timeout',
      );
    } on VendorError {
      rethrow;
    } catch (error) {
      throw VendorError(
        kind: VendorErrorKind.transport,
        message: 'OpenAI transport failure: $error',
      );
    }

    return _mapResponse(response);
  }

  /// Provider-specific transport encoding of already-compiled instructions.
  /// Does not rechoose WHAT or invent cognitive decisions.
  Map<String, dynamic> _serialize(VendorRequest request) {
    final compiled = request.compiled;
    return {
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content': compiled.systemContent,
        },
        {
          'role': 'user',
          'content': compiled.userContent,
        },
      ],
      'temperature': 0.28,
      'max_tokens': 80,
      'stream': false,
    };
  }

  VendorResponse _mapResponse(http.Response response) {
    final status = response.statusCode;
    if (status == 401 || status == 403) {
      throw VendorError(
        kind: VendorErrorKind.auth,
        message: 'OpenAI auth failed ($status)',
      );
    }
    if (status < 200 || status >= 300) {
      throw VendorError(
        kind: VendorErrorKind.transport,
        message: 'OpenAI HTTP $status',
      );
    }

    final dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (error) {
      throw VendorError(
        kind: VendorErrorKind.unusable,
        message: 'OpenAI response was not JSON: $error',
      );
    }

    final text = _extractText(data);
    if (text == null || text.trim().isEmpty) {
      throw const VendorError(
        kind: VendorErrorKind.unusable,
        message: 'OpenAI returned empty or unusable text',
      );
    }

    try {
      return VendorResponse(text: text.trim());
    } on ArgumentError catch (error) {
      throw VendorError(
        kind: VendorErrorKind.unusable,
        message: 'OpenAI text rejected: $error',
      );
    }
  }

  /// Exactly one completed text — first choice only. No streaming chunks.
  String? _extractText(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices.first;
    if (first is! Map) return null;
    final message = first['message'];
    if (message is! Map) return null;
    final content = message['content'];
    if (content is! String) return null;
    return content;
  }
}
