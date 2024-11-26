// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProfileAdapter extends TypeAdapter<Profile> {
  @override
  final int typeId = 0;

  @override
  Profile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Profile(
      id: fields[0] as int?,
      name: fields[1] as String,
      imagePath: fields[2] as String?,
      email: fields[3] as String,
      phone: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Profile obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.phone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MemberAdapter extends TypeAdapter<Member> {
  @override
  final int typeId = 1;

  @override
  Member read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Member(
      id: fields[0] as int?,
      name: fields[1] as String,
      phone: fields[2] as String,
      imagePath: fields[3] as String?,
      groupsIncluded: (fields[4] as List?)?.cast<Group>(),
      totalAmountOwedByMe: fields[5] as double,
      createdAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Member obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.imagePath)
      ..writeByte(4)
      ..write(obj.groupsIncluded)
      ..writeByte(5)
      ..write(obj.totalAmountOwedByMe)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GroupAdapter extends TypeAdapter<Group> {
  @override
  final int typeId = 2;

  @override
  Group read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Group(
      id: fields[0] as int?,
      groupName: fields[1] as String,
      groupImage: fields[2] as String,
      category: fields[3] as String?,
      members: (fields[4] as List).cast<Member>(),
      expenses: (fields[5] as List?)?.cast<Expense>(),
      categories: (fields[7] as List?)?.cast<String>(),
      createdAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Group obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupName)
      ..writeByte(2)
      ..write(obj.groupImage)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.members)
      ..writeByte(5)
      ..write(obj.expenses)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.categories);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExpenseSplitAdapter extends TypeAdapter<ExpenseSplit> {
  @override
  final int typeId = 4;

  @override
  ExpenseSplit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExpenseSplit(
      id: fields[0] as int?,
      member: fields[1] as Member,
      amount: fields[2] as double,
      percentage: fields[3] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseSplit obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.member)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.percentage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseSplitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 5;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      id: fields[0] as int?,
      totalAmount: fields[1] as double,
      divisionMethod: fields[2] as DivisionMethod,
      paidByMember: fields[3] as Member,
      splits: (fields[4] as List).cast<ExpenseSplit>(),
      group: fields[5] as Group?,
      description: fields[6] as String,
      category: fields[8] as String?,
      note: fields[9] as String?,
      attachments: (fields[10] as List?)?.cast<String>(),
      createdAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.totalAmount)
      ..writeByte(2)
      ..write(obj.divisionMethod)
      ..writeByte(3)
      ..write(obj.paidByMember)
      ..writeByte(4)
      ..write(obj.splits)
      ..writeByte(5)
      ..write(obj.group)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.note)
      ..writeByte(10)
      ..write(obj.attachments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DivisionMethodAdapter extends TypeAdapter<DivisionMethod> {
  @override
  final int typeId = 3;

  @override
  DivisionMethod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DivisionMethod.equal;
      case 1:
        return DivisionMethod.unequal;
      case 2:
        return DivisionMethod.percentage;
      default:
        return DivisionMethod.equal;
    }
  }

  @override
  void write(BinaryWriter writer, DivisionMethod obj) {
    switch (obj) {
      case DivisionMethod.equal:
        writer.writeByte(0);
        break;
      case DivisionMethod.unequal:
        writer.writeByte(1);
        break;
      case DivisionMethod.percentage:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DivisionMethodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
