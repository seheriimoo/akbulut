import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'conversation_dna.dart';
import 'conversation_phase.dart';
import 'llm_invocation_package.dart';
import 'vendor_provider.dart';

/// OpenAI chat-completions transport adapter.
///
/// Implements [VendorProvider] only: serializes one sealed [VendorRequest],
/// performs one non-streaming HTTP completion, returns one [VendorResponse]
/// or throws [VendorError].
///
/// Owns no WHAT, release, protocol, exit, DNA enforcement, retries, timeout
/// policy, fallback, or Conversation emission. When [VendorRequest.timeout] is
/// present, enforces that client-supplied limit on the wire only.
/// Config (API key / model) stays outside cognitive ownership and NightSession.
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

  /// Provider-specific serialization of already-sealed package contents.
  /// Does not rechoose WHAT or invent cognitive decisions.
  Map<String, dynamic> _serialize(VendorRequest request) {
    final package = request.package;
    return {
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content': _systemContent(package),
        },
        {
          'role': 'user',
          'content':
              'Realize only the sealed WHAT (${package.what.name}) as '
              'exactly one short utterance. Stay inside that WHAT semantic '
              'signature; do not drift into another phase.',
        },
      ],
      'temperature': 0.4,
      'max_tokens': 80,
      'stream': false,
    };
  }

  String _systemContent(LlmInvocationPackage package) {
    final principles = ConversationDNA.principles
        .map((p) => '- ${p.name}: ${p.rule}')
        .join('\n');
    final antiRules = ConversationDNA.antiRules
        .map((r) => '- ${r.name}: ${r.reason}')
        .join('\n');
    final required = package.llmRequired.map((item) => '- $item').join('\n');
    final allowed = package.llmAllowed.map((item) => '- $item').join('\n');
    final forbidden = package.llmForbidden.map((item) => '- $item').join('\n');

    // Touch optional shaping presence only — never narrate analysis/storage.
    final hasShaping = package.understanding != null ||
        package.workingMind != null;
    final shapingNote = hasShaping
        ? 'Attentive wording from supplied expression context is allowed.'
        : 'No additional shaping context was supplied.';

    // Bound DNA instance is required on the package; principles/anti-rules above.
    assert(identical(package.dna, ConversationDNA.instance));

    return '''
You are a transport HOW adapter. Realize only the sealed speakable WHAT.
Do not choose release, protocol, exit, silence, or a different WHAT.
Emit exactly one short natural-language utterance (one sentence, no question).
No multi-message bundles. Prefer the fewest helpful words.

Sealed WHAT semantic signature (realize this move only):
${_sealedWhatSignature(package.what)}

Required:
$required

Allowed:
$allowed

Forbidden:
$forbidden

Conversation DNA principles:
$principles

Conversation DNA anti-rules:
$antiRules

$shapingNote
''';
  }

  /// HOW-only wording guidance for the already-sealed WHAT.
  /// Does not choose or rewrite WHAT; describes the sealed move to realize.
  String _sealedWhatSignature(ConversationPhase what) {
    switch (what) {
      case ConversationPhase.validation:
        return 'validation — acknowledge that what they shared makes sense; '
            'you understand / hear them. Soft receipt only '
            '(e.g. that makes sense / I hear that / I understand). '
            'Do not name the load, grant permission, invite release, or close.';
      case ConversationPhase.naming:
        return 'naming — gently name something still holding on / weighing / '
            'lingering / on their mind. Do not validate, grant permission, '
            'invite release, or close.';
      case ConversationPhase.permission:
        return 'permission — ease pressure: they do not have to / don\'t have '
            'to solve this tonight. Do not validate, name the load, invite '
            'release, or close.';
      case ConversationPhase.release:
        return 'release — invite setting the load down: let this rest / let '
            'it rest / set this down / let go for now. Do not validate, name, '
            'grant permission, or close.';
      case ConversationPhase.continuity:
        return 'continuity — close gently: nothing more / that\'s enough / '
            'enough for now. Do not validate, name, grant permission, or '
            'invite release.';
      case ConversationPhase.audio:
      case ConversationPhase.silence:
        // Non-speakable WHAT never reaches serialize (package invariant).
        return what.name;
    }
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
