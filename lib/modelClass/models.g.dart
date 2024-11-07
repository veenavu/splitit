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
      name: fields[0] as String,
      imagePath: fields[1] as String?,
      email: fields[2] as String,
      phone: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Profile obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
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
      name: fields[0] as String,
      phone: fields[1] as String,
      imagePath: fields[2] as String?,
      groupsIncluded: (fields[3] as List?)?.cast<Group>(),
      totalAmountOwedByMe: fields[4] as double,
      createdAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Member obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.phone)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.groupsIncluded)
      ..writeByte(4)
      ..write(obj.totalAmountOwedByMe)
      ..writeByte(5)
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
      groupName: fields[0] as String,
      groupImage: fields[1] as String,
      category: fields[2] as String?,
      members: (fields[3] as List).cast<Member>(),
      expenses: (fields[4] as List?)?.cast<Expense>(),
      categories: (fields[6] as List?)?.cast<String>(),
      createdAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Group obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.groupName)
      ..writeByte(1)
      ..write(obj.groupImage)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.members)
      ..writeByte(4)
      ..write(obj.expenses)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
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
      member: fields[0] as Member,
      amount: fields[1] as double,
      percentage: fields[2] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseSplit obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.member)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
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
      totalAmount: fields[0] as double,
      divisionMethod: fields[1] as DivisionMethod,
      paidByMember: fields[2] as Member,
      splits: (fields[3] as List).cast<ExpenseSplit>(),
      group: fields[4] as Group?,
      description: fields[5] as String,
      category: fields[7] as String?,
      note: fields[8] as String?,
      attachments: (fields[9] as List?)?.cast<String>(),
      createdAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.totalAmount)
      ..writeByte(1)
      ..write(obj.divisionMethod)
      ..writeByte(2)
      ..write(obj.paidByMember)
      ..writeByte(3)
      ..write(obj.splits)
      ..writeByte(4)
      ..write(obj.group)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.note)
      ..writeByte(9)
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
