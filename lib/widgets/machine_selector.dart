/// Dropdown selector for Machine IDs with natural sorting, custom addition, and `>` next machine button.
library;

import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/natural_sort.dart';

class MachineSelector extends StatelessWidget {
  final String selectedMachine;
  final ValueChanged<String> onChanged;
  final bool allowCustom;

  const MachineSelector({
    super.key,
    required this.selectedMachine,
    required this.onChanged,
    this.allowCustom = true,
  });

  void _selectNextMachine(List<String> machines) {
    if (machines.isEmpty) return;
    final currentIndex = machines.indexOf(selectedMachine);
    if (currentIndex == -1 || currentIndex == machines.length - 1) {
      onChanged(machines.first);
    } else {
      onChanged(machines[currentIndex + 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final machines = List<String>.from(AppConstants.defaultMachines);
    if (!machines.contains(selectedMachine) && selectedMachine.isNotEmpty) {
      machines.add(selectedMachine);
    }
    machines.sortNaturally();

    final activeMachine = machines.contains(selectedMachine) ? selectedMachine : machines.first;

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: activeMachine,
            decoration: const InputDecoration(
              labelText: 'M.No (Machine)',
              prefixIcon: Icon(Icons.precision_manufacturing_outlined),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: [
              ...machines.map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
                  )),
              if (allowCustom)
                const DropdownMenuItem(
                  value: '__ADD_NEW__',
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: 6),
                      Text('+ Custom Machine', style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                ),
            ],
            onChanged: (val) {
              if (val == null) return;
              if (val == '__ADD_NEW__') {
                _showAddCustomMachineDialog(context);
              } else {
                onChanged(val);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Next Machine (Natural Order)',
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _selectNextMachine(machines),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.primary.withAlpha(80)),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 20,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddCustomMachineDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Machine'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Machine ID (e.g. N1, A13)',
            hintText: 'Enter machine serial',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newId = textController.text.trim().toUpperCase();
              if (newId.isNotEmpty) {
                onChanged(newId);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
