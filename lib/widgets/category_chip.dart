import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_helpers.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    this.compact = false,
  });

  final String category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppHelpers.categoryIcon(category),
            size: compact ? 14 : 16,
            color: AppColors.mutedText,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              category,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
