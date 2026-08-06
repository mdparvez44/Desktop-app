/// Compact plant checklist / chip selector row for desktop input entry.
library;

import 'package:flutter/material.dart';
import '../utils/constants.dart';

class PlantSelector extends StatelessWidget {
  final String selectedPlant;
  final ValueChanged<String> onChanged;

  const PlantSelector({
    super.key,
    required this.selectedPlant,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plants = AppConstants.defaultPlants;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.factory_outlined,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              'Plant',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: plants.map((plant) {
            final isSelected = selectedPlant == plant;
            return FilterChip(
              label: Text(
                plant,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
              selected: isSelected,
              selectedColor: theme.colorScheme.primary,
              checkmarkColor: theme.colorScheme.onPrimary,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              showCheckmark: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              onSelected: (selected) {
                if (selected) onChanged(plant);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
