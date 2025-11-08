// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracked_text.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrackedTextAdapter extends TypeAdapter<TrackedText> {
  @override
  final int typeId = 0;

  @override
  TrackedText read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrackedText(
      fields[0] as String,
      (fields[1] as List).cast<String>(),
      fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TrackedText obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.keywords)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackedTextAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
