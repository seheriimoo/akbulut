import 'compiled_instruction_package.dart';
import 'llm_invocation_package.dart';

/// Transport-only vendor adapter behind [LanguageModelClient].
///
/// Accepts one package-derived [VendorRequest] and returns exactly one
/// completed text [VendorResponse], or surfaces failure as [VendorError].
///
/// Owns wire transport only. Does not own WHAT, release, protocol, exit,
/// DNA/Output Contract enforcement, memory, retries, or Conversation emission.
/// Does not perform cognitive prompt translation — that belongs to
/// [ConversationCompiler] via [CompiledInstructionPackage].
///
/// V1: returns a completed single text result — no streaming into the
/// Conversation stage.
abstract class VendorProvider {
  /// Complete one sealed provider request.
  ///
  /// Success: exactly one non-empty text via [VendorResponse].
  /// Failure: throw [VendorError] (no silent empty success).
  Future<VendorResponse> complete(VendorRequest request);
}

/// Provider request derived from one sealed package + compiled instructions.
///
/// Built by [LanguageModelClient] after ConversationCompiler succeeds.
/// Contains no credentials, API keys, model endpoints, or cognitive
/// decision authority.
class VendorRequest {
  /// Sealed package this request realizes (speakable WHAT + bounds + DNA).
  final LlmInvocationPackage package;

  /// Deterministic compiled instruction material for transport serialization.
  final CompiledInstructionPackage compiled;

  /// Client-supplied transport timeout. Enforced on the wire by the provider.
  final Duration? timeout;

  const VendorRequest({
    required this.package,
    required this.compiled,
    this.timeout,
  });
}

/// Successful provider completion: one completed natural-language text.
///
/// Empty text is never a successful speech result.
class VendorResponse {
  final String text;

  VendorResponse({required this.text}) {
    if (text.trim().isEmpty) {
      throw ArgumentError.value(
        text,
        'text',
        'VendorResponse must not carry empty text as success',
      );
    }
  }
}

/// Classification of provider/transport failures.
///
/// Product-level error policy remains owned by [LanguageModelClient].
enum VendorErrorKind {
  /// Network / SDK / HTTP transport failure.
  transport,

  /// Auth or credential failure at the provider boundary.
  auth,

  /// Wire timeout under the client-supplied limit.
  timeout,

  /// Provider returned empty, multi-message, or otherwise unusable text.
  unusable,
}

/// Provider-detected transport failure surfaced to [LanguageModelClient].
///
/// Vendors do not own product-level error policy or cognitive re-decision.
class VendorError implements Exception {
  final VendorErrorKind kind;
  final String message;

  const VendorError({
    required this.kind,
    required this.message,
  });

  @override
  String toString() => 'VendorError(${kind.name}): $message';
}
