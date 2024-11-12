

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:splitit/screens/add_group.dart';

void showMemberAddingBottomSheet(
    {required BuildContext context,
    Function(List<Contact>?)? onContactsSelected}) async {
  final result = await showModalBottomSheet<List<Contact>>(
    context: context,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.96,
    ),
    isScrollControlled: true,
    builder: (context) => MemberAdding(
      onContactsSelected: (contacts) {
        Navigator.pop(context, contacts);
      },
    ),
  );
  onContactsSelected?.call(result);
}