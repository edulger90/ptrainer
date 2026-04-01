class QueryPlanDebugEntry {
  final String label;
  final String sql;
  final List<Object?> arguments;
  final List<String> details;

  const QueryPlanDebugEntry({
    required this.label,
    required this.sql,
    required this.arguments,
    required this.details,
  });

  bool get usesIndex =>
      details.any((detail) => detail.toUpperCase().contains('INDEX'));
}
