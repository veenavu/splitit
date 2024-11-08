import 'dart:io';

import 'package:flutter/material.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';

class GroupSettings extends StatefulWidget {
  final Group group;

  const GroupSettings({super.key, required this.group});

  @override
  State<GroupSettings> createState() => _GroupSettingsState();
}

class _GroupSettingsState extends State<GroupSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Group Settings"),
        actions:  [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: (){
            ExpenseManagerService.deleteGroup(widget.group);
            Navigator.pop(context);
            Navigator.pop(context);
          }),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.file(
                    File(widget.group.groupImage),
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Center(
                child: Text(
              widget.group.groupName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            )),
            const SizedBox(height: 30),
            Align(alignment: Alignment.centerLeft, child: Text("Members: ${widget.group.members.length}")),
            const SizedBox(
              height: 5,
            ),
            Expanded(
              child: ListView.builder(
                  itemCount: widget.group.members.length,
                  itemBuilder: (context, index) {
                    return ListTile(leading: const CircleAvatar(), title: Text(widget.group.members[index].name));
                  }),
            )
          ],
        ),
      ),
    );
  }
}
