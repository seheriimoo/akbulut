import 'living_mind_model.dart';
import 'memory_audit_log.dart';

class MemoryUpdateResult {
  final LivingMindModel model;

  final MemoryAuditLog auditLog;

  const MemoryUpdateResult({required this.model, required this.auditLog});
}
