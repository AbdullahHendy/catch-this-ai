// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracked_keyword.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrackedKeywordAdapter extends TypeAdapter<TrackedKeyword> {
  @override
  final int typeId = 0;

  @override
  TrackedKeyword read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrackedKeyword(
      fields[0] as String,
      fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TrackedKeyword obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.keyword)
      ..writeByte(1)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackedKeywordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
