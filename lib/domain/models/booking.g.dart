// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookingAdapter extends TypeAdapter<Booking> {
  @override
  final int typeId = 3;

  @override
  Booking read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Booking(
      id: fields[0] as String,
      eventId: fields[1] as String?,
      labId: fields[2] as String,
      userId: fields[3] as String,
      title: fields[4] as String,
      date: fields[5] as DateTime,
      start: fields[6] as DateTime,
      end: fields[7] as DateTime,
      repeatRule: fields[8] as RepeatRule,
      status: fields[9] as BookingStatus,
      participants: fields[10] as int,
      createdAt: fields[11] as DateTime,
      notes: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Booking obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.eventId)
      ..writeByte(2)
      ..write(obj.labId)
      ..writeByte(3)
      ..write(obj.userId)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.start)
      ..writeByte(7)
      ..write(obj.end)
      ..writeByte(8)
      ..write(obj.repeatRule)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.participants)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
