import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  const CustomDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.icon,
    this.validator,
    this.includeAllOption = false,
  });

  final String label;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final IconData? icon;
  final String? Function(String?)? validator;
  final bool includeAllOption;

  @override
  Widget build(BuildContext context) {
    final values = includeAllOption ? ['All', ...items] : items;

    return DropdownButtonFormField<String>(
      initialValue: value,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
      ),
      items: values
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
