// First create a custom SearchDelegate
import 'package:flutter/material.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/group_details.dart';

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
      itemBuilder: (context, index) {
        final group = searchResults[index];
        return ListTile(
          title: Text(group.groupName),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => GroupDetails(
                          groupItem: group,
                        ))).then((value) {
              callback.call();
            });
          },
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
