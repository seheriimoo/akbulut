import 'living_mind_model.dart';

/// Read-only view of the LivingMindModel.
///
/// This object exists only for the current NightSession.
/// It prevents cognitive engines from depending directly
/// on the mutable lifecycle of persistent memory.
class WorkingMindView {
  final LivingMindModel model;

  const WorkingMindView({required this.model});
}
