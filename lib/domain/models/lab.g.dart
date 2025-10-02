// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lab.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LabAdapter extends TypeAdapter<Lab> {
  @override
  final int typeId = 1;

  @override
  Lab read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Lab(
      id: fields[0] as String,
      name: fields[1] as String,
      location: fields[2] as String,
      capacity: fields[3] as int,
      description: fields[4] as String,
      createdAt: fields[5] as DateTime,
      isActive: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Lab obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.location)
      ..writeByte(3)
      ..write(obj.capacity)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
