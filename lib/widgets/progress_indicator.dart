import 'package:flutter/material.dart';
import 'package:pronto/constants.dart';

class CustomProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps = 12;

  const CustomProgressIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(totalSteps, (index) {
          final isActive = index < currentStep;
          final isCurrent = index == currentStep - 1;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: isCurrent ? 24 : 8, // wider if current step
            height: 8,
            decoration: BoxDecoration(
              color: isActive || isCurrent
                  ? AppColors
                        .primary // blue if completed or current step
                  : AppColors.textSecondary.withValues(alpha: 77),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          '$currentStep/$totalSteps',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
