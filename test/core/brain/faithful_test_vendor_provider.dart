import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/vendor_provider.dart';

/// Test-only transport stub. Not a production vendor.
///
/// Returns the former deterministic placeholder texts so Sprint 5/6
/// expression expectations remain stable without a commercial vendor.
class FaithfulTestVendorProvider implements VendorProvider {
  const FaithfulTestVendorProvider();

  @override
  Future<VendorResponse> complete(VendorRequest request) async {
    final what = request.package.what;
    final hasShaping = request.package.understanding != null ||
        request.package.workingMind != null;
    final text = hasShaping ? _attentiveFor(what) : _minimalFor(what);
    return VendorResponse(text: text);
  }

  String _minimalFor(ConversationPhase what) {
    switch (what) {
      case ConversationPhase.validation:
        return 'That makes sense.';
      case ConversationPhase.naming:
        return 'Something is still holding on.';
      case ConversationPhase.permission:
        return 'You do not have to solve this tonight.';
      case ConversationPhase.release:
        return 'You can let this rest for now.';
      case ConversationPhase.continuity:
        return 'Nothing more is needed right now.';
      case ConversationPhase.neutralEntry:
        return "Hi whenever you're ready.";
      case ConversationPhase.audio:
      case ConversationPhase.silence:
        throw VendorError(
          kind: VendorErrorKind.unusable,
          message: 'Non-speech WHAT must not reach VendorProvider',
        );
    }
  }

  String _attentiveFor(ConversationPhase what) {
    switch (what) {
      case ConversationPhase.validation:
        return 'I hear that.';
      case ConversationPhase.naming:
        return 'Something is still weighing on you.';
      case ConversationPhase.permission:
        return "You don't have to solve this tonight.";
      case ConversationPhase.release:
        return 'You can let it rest for now.';
      case ConversationPhase.continuity:
        return "I'm preparing a little quiet for you now.";
      case ConversationPhase.neutralEntry:
        return "Hello whenever you're ready.";
      case ConversationPhase.audio:
      case ConversationPhase.silence:
        throw VendorError(
          kind: VendorErrorKind.unusable,
          message: 'Non-speech WHAT must not reach VendorProvider',
        );
    }
  }
}
