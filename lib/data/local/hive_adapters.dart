import 'package:hive/hive.dart';
import '../../domain/models/user.dart';
import '../../domain/models/lab.dart';
import '../../domain/models/event.dart';
import '../../domain/models/booking.dart';
import '../../domain/enums/role.dart';
import '../../domain/enums/booking_status.dart';
import '../../domain/enums/repeat_rule.dart';

/// Hive adapters for local storage
/// Manual adapters - no code generation needed
class HiveAdapters {
  static void registerAdapters() {
    // Register enum adapters
    Hive.registerAdapter(RoleAdapter());
    Hive.registerAdapter(BookingStatusAdapter());
    Hive.registerAdapter(RepeatRuleAdapter());
    
    // Register model adapters
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(LabAdapter());
    Hive.registerAdapter(EventAdapter());
    Hive.registerAdapter(BookingAdapter());
  }
}

// Model Adapters
class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    
    return User(
      id: fields[0] as String,
      username: fields[1] as String,
      fullname: fields[2] as String,
      email: fields[3] as String,
      mssv: fields[4] as String?,
      status: fields[5] as int? ?? 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[6] as int),
      lastUpdatedAt: DateTime.fromMillisecondsSinceEpoch(fields[7] as int),
      roles: (fields[8] as List?)?.cast<Role>() ?? [Role.student],
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(9) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.fullname)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.mssv)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(7)
      ..write(obj.lastUpdatedAt.millisecondsSinceEpoch)
      ..writeByte(8)
      ..write(obj.roles);
  }
}

class LabAdapter extends TypeAdapter<Lab> {
  @override
  final int typeId = 1;

  @override
  Lab read(BinaryReader reader) {
    return Lab(
      id: reader.readString(),
      name: reader.readString(),
      location: reader.readString(),
      capacity: reader.readInt(),
      description: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      isActive: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, Lab obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.location);
    writer.writeInt(obj.capacity);
    writer.writeString(obj.description);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeBool(obj.isActive);
  }
}

class EventAdapter extends TypeAdapter<Event> {
  @override
  final int typeId = 2;

  @override
  Event read(BinaryReader reader) {
    return Event(
      id: reader.readString(),
      labId: reader.readString(),
      title: reader.readString(),
      description: reader.readString(),
      start: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      end: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      createdBy: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      isActive: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, Event obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.labId);
    writer.writeString(obj.title);
    writer.writeString(obj.description);
    writer.writeInt(obj.start.millisecondsSinceEpoch);
    writer.writeInt(obj.end.millisecondsSinceEpoch);
    writer.writeString(obj.createdBy);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeBool(obj.isActive);
  }
}

class BookingAdapter extends TypeAdapter<Booking> {
  @override
  final int typeId = 3;

  @override
  Booking read(BinaryReader reader) {
    return Booking(
      id: reader.readString(),
      eventId: reader.readBool() ? reader.readString() : null,
      labId: reader.readString(),
      userId: reader.readString(),
      title: reader.readString(),
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      start: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      end: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      repeatRule: RepeatRule.values[reader.readByte()],
      status: BookingStatus.values[reader.readByte()],
      participants: reader.readInt(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      notes: reader.readBool() ? reader.readString() : null,
    );
  }

  @override
  void write(BinaryWriter writer, Booking obj) {
    writer.writeString(obj.id);
    writer.writeBool(obj.eventId != null);
    if (obj.eventId != null) {
      writer.writeString(obj.eventId!);
    }
    writer.writeString(obj.labId);
    writer.writeString(obj.userId);
    writer.writeString(obj.title);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeInt(obj.start.millisecondsSinceEpoch);
    writer.writeInt(obj.end.millisecondsSinceEpoch);
    writer.writeByte(obj.repeatRule.index);
    writer.writeByte(obj.status.index);
    writer.writeInt(obj.participants);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeBool(obj.notes != null);
    if (obj.notes != null) {
      writer.writeString(obj.notes!);
    }
  }
}

// Enum Adapters
class RoleAdapter extends TypeAdapter<Role> {
  @override
  final int typeId = 10;

  @override
  Role read(BinaryReader reader) {
    return Role.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, Role obj) {
    writer.writeByte(obj.index);
  }
}

class BookingStatusAdapter extends TypeAdapter<BookingStatus> {
  @override
  final int typeId = 11;

  @override
  BookingStatus read(BinaryReader reader) {
    return BookingStatus.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, BookingStatus obj) {
    writer.writeByte(obj.index);
  }
}

class RepeatRuleAdapter extends TypeAdapter<RepeatRule> {
  @override
  final int typeId = 12;

  @override
  RepeatRule read(BinaryReader reader) {
    return RepeatRule.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, RepeatRule obj) {
    writer.writeByte(obj.index);
  }
}
