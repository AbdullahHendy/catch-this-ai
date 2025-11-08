import 'package:hive/hive.dart';

part 'tracked_text.g.dart';

/// Domain model representing a tracked text with its timestamp
/// It will also serve as a Hive data model (Adapter will be generated for it)
@HiveType(typeId: 0)
class TrackedText {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final List<String> keywords;

  @HiveField(2)
  final DateTime timestamp;

  const TrackedText(this.text, this.keywords, this.timestamp);
}

/// Extension to serialize/deserialize for isolates communication
extension TrackedTextSerialization on TrackedText {
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'keywords': keywords,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static TrackedText fromMap(Map<String, dynamic> map) {
    return TrackedText(
      map['text'] as String? ?? '',
      (map['keywords'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      DateTime.parse(
        map['timestamp'] as String? ?? DateTime(2000).toIso8601String(),
      ),
    );
  }
}
