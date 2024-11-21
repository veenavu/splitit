

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:splitit/screens/group/add_group.dart';
void showMemberAddingBottomSheet({
  required BuildContext context,
  Function(List<Contact>?)? onContactsSelected,
}) async {
  final result = await showModalBottomSheet<List<Contact>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // Allows for custom styling
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.deepPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                // Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Text(
                    "Add Members",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Expanded Member List
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: MemberAdding(
                      onContactsSelected: (contacts) {
                        Navigator.pop(context, contacts);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  onContactsSelected?.call(result);
}





//__________________________________________________________________


class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  final bool centerTitle;
  final Color backgroundColor;
  final Gradient? gradient;
  final double elevation;
  final BorderRadius? borderRadius;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions = const [],
    this.centerTitle = false,
    this.backgroundColor = Colors.purple,
    this.gradient,
    this.elevation = 4,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: centerTitle,
      actions: actions,
      backgroundColor: backgroundColor,
      elevation: elevation,
      flexibleSpace: gradient != null
          ? Container(
        decoration: BoxDecoration(
          gradient: gradient,
        ),
      )
          : null,
      shape: borderRadius != null
          ? RoundedRectangleBorder(
        borderRadius: borderRadius!,
      )
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
