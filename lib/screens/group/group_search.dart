// First create a custom SearchDelegate
import 'package:flutter/material.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/group/group_details.dart';

class GroupSearchDelegate extends SearchDelegate<String> {
  final List<Group> groups;
  final VoidCallback callback;

  GroupSearchDelegate(this.groups, this.callback);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final searchResults = groups.where((group) => group.groupName.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: searchResults.length,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemBuilder: (context, index) {
        final group = searchResults[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.purple.shade100,
              child: Text(
                group.groupName.isNotEmpty ? group.groupName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            title: Text(
              group.groupName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupDetails(
                    groupItem: group,
                  ),
                ),
              ).then((value) {
                callback.call();
              });
            },
          ),
        );
      },
    );

  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Search for groups...'),
      );
    }
    return buildResults(context);
  }
}

// Then modify your Scaffold:
