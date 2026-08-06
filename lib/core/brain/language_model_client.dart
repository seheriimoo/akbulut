import 'dart:async';

import 'conversation_dna.dart';
import 'conversation_utterance.dart';
import 'llm_invocation_package.dart';
import 'vendor_provider.dart';

/// LanguageModelClient
///
/// HOW-only expression adapter for the Conversation plane.
///
/// Accepts exactly one [LlmInvocationPackage] and returns exactly one
/// non-empty candidate [ConversationUtterance] realizing the sealed WHAT.
///
/// Depends only on the [VendorProvider] abstraction for vendor transport —
/// never on a concrete vendor SDK. Builds one [VendorRequest] from the
/// sealed package, invokes the configured provider, and maps
/// [VendorResponse] to one candidate utterance.
///
/// Owns vendor timeout policy and limited same-request retry for transient
/// transport failures only. Propagates [VendorError] without fallback,
/// DNA enforcement, release, protocol, exit, or memory ownership.
class LanguageModelClient {
  /// Default client-owned vendor call timeout (V1).
  static const Duration defaultTimeout = Duration(seconds: 10);

  /// Sole vendor transport dependency. Interchangeable without changing
  /// PromptArchitecture, ConversationEngine, or UtteranceGuard.
  final VendorProvider? vendorProvider;

  /// Client-owned timeout supplied on every [VendorRequest].
  final Duration timeout;

  const LanguageModelClient({
    this.vendorProvider,
    this.timeout = defaultTimeout,
  });

  /// Realize the sealed package as a single non-empty candidate utterance.
  ///
  /// Builds one [VendorRequest] (with [timeout]), invokes the provider,
  /// and maps completed text to one [ConversationUtterance].
  ///
  /// On a transient [VendorError], retries once with the identical request.
  /// Non-transient errors and a failed retry propagate without fallback.
  Future<ConversationUtterance> realize(LlmInvocationPackage package) async {
    _requireFrozenBounds(package);
    _requireBoundDna(package.dna);

    final provider = vendorProvider;
    if (provider == null) {
      throw StateError(
        'LanguageModelClient requires a configured VendorProvider',
      );
    }

    // Identical request object for the initial call and any single retry.
    final request = VendorRequest(package: package, timeout: timeout);

    final response = await _invoke(provider, request);
    return ConversationUtterance(text: response.text);
  }

  /// Initial invoke + at most one retry on transient failure.
  Future<VendorResponse> _invoke(
    VendorProvider provider,
    VendorRequest request,
  ) async {
    try {
      return await _completeOnce(provider, request);
    } on VendorError catch (error) {
      if (!_isTransient(error.kind)) rethrow;
      // Maximum one retry; same sealed request only.
      return await _completeOnce(provider, request);
    }
  }

  /// Single provider completion under client-owned timeout.
  Future<VendorResponse> _completeOnce(
    VendorProvider provider,
    VendorRequest request,
  ) async {
    try {
      return await provider.complete(request).timeout(timeout);
    } on TimeoutException {
      throw const VendorError(
        kind: VendorErrorKind.timeout,
        message: 'VendorProvider exceeded LanguageModelClient timeout',
      );
    } on VendorError {
      rethrow;
    }
  }

  /// Transient transport failures eligible for one retry.
  static bool _isTransient(VendorErrorKind kind) {
    switch (kind) {
      case VendorErrorKind.transport:
      case VendorErrorKind.timeout:
        return true;
      case VendorErrorKind.auth:
      case VendorErrorKind.unusable:
        return false;
    }
  }

  void _requireFrozenBounds(LlmInvocationPackage package) {
    if (!_sameStrings(package.llmRequired, LlmContractBounds.required) ||
        !_sameStrings(package.llmAllowed, LlmContractBounds.allowed) ||
        !_sameStrings(package.llmForbidden, LlmContractBounds.forbidden)) {
      throw StateError(
        'LanguageModelClient requires frozen LLM Contract bounds on the package',
      );
    }
  }

  void _requireBoundDna(ConversationDNA dna) {
    if (!identical(dna, ConversationDNA.instance)) {
      throw StateError(
        'LanguageModelClient requires the bound ConversationDNA on the package',
      );
    }
  }

  bool _sameStrings(List<String> actual, List<String> expected) {
    if (actual.length != expected.length) return false;
    for (var i = 0; i < actual.length; i++) {
      if (actual[i] != expected[i]) return false;
    }
    return true;
  }
}
