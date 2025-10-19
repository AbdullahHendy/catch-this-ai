import 'package:hive/hive.dart';

part 'tracked_keyword.g.dart';

/// Domain model representing a tracked keyword with its timestamp
/// It will also serve as a Hive data model (Adapter will be generated for it)
@HiveType(typeId: 0)
class TrackedKeyword {
  @HiveField(0)
  final String keyword;

  @HiveField(1)
  final DateTime timestamp;

  const TrackedKeyword(this.keyword, this.timestamp);
}
