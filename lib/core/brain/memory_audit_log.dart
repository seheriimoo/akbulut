class MemoryAuditLog {
  final List<String> entries;

  const MemoryAuditLog({this.entries = const []});

  bool get isEmpty => entries.isEmpty;

  bool get isNotEmpty => entries.isNotEmpty;

  MemoryAuditLog add(String entry) {
    return MemoryAuditLog(entries: [...entries, entry]);
  }
}
