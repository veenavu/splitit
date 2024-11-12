import 'package:flutter/material.dart';

class CustomAppbar extends StatelessWidget {
  Text title;
  Icon leading;
  List<Widget> actions;
  Color backgroundColor;
  bool centerTitle;
  Color foregroundColor;
   CustomAppbar({
    super.key,
    required this.title,
    required this.leading,
    required this.actions,
    required this.backgroundColor,
    required this.centerTitle,
    required this.foregroundColor});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      leading: leading,
      actions: actions,
      backgroundColor: backgroundColor,
      centerTitle: centerTitle,
      foregroundColor: foregroundColor,
    );
  }
}
