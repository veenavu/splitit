import 'package:flutter/material.dart';

class GroupTypeSelector extends StatelessWidget {
  final List<String> groupTypes;
  final String? selectedType;
  final Function(String?) onTypeSelected;

  const GroupTypeSelector({
    Key? key,
    required this.groupTypes,
    required this.selectedType,
    required this.onTypeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          children: groupTypes
              .map((type) => RawChip(
            label: Text(
              type,
              style: TextStyle(
                color: selectedType == type ? Colors.white : Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
            selected: selectedType == type,
            onSelected: (bool selected) {
              onTypeSelected(selected ? type : null);
            },
            selectedColor: Colors.purple,
            backgroundColor: Colors.purple.shade50,
            showCheckmark: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.1),
            pressElevation: 6,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ))
              .toList(),
        ),
      ],
    );
  }
}