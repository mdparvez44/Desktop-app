// Application Settings Screen for configuring export save location, automatic export toggle, theme switch, and master configuration.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const SettingsScreen({
    super.key,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with optional Back button
          Row(
            children: [
              if (onBack != null) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back to Application',
                  onPressed: onBack,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                'Settings',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Configure application theme, export location, and master configuration management',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Master Configuration Group Header
          Text(
            'Master Configuration Management',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          // 1. Machine Series Management Card
          _buildConfigurationCard(
            context,
            title: 'Machine',
            subtitle: 'Manage Machine Series list',
            icon: Icons.precision_manufacturing_outlined,
            onAdd: () => _showAddMachineDialog(context, settingsProvider),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: settingsProvider.machines.map((m) {
                return Chip(
                  label: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _confirmRemoveMachine(context, settingsProvider, m),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Product Code Management Card
          _buildConfigurationCard(
            context,
            title: 'Product Code',
            subtitle: 'Manage Product Codes',
            icon: Icons.qr_code_2_outlined,
            onAdd: () => _showAddProductCodeDialog(context, settingsProvider),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: settingsProvider.productCodes.map((code) {
                return Chip(
                  label: Text(code, style: const TextStyle(fontWeight: FontWeight.w600)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _confirmRemoveProductCode(context, settingsProvider, code),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Plant Management Card
          _buildConfigurationCard(
            context,
            title: 'Plant',
            subtitle: 'Manage Plants',
            icon: Icons.factory_outlined,
            onAdd: () => _showAddPlantDialog(context, settingsProvider),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: settingsProvider.plants.map((plant) {
                return Chip(
                  label: Text(plant, style: const TextStyle(fontWeight: FontWeight.bold)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _confirmRemovePlant(context, settingsProvider, plant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Good Options Management Card
          _buildConfigurationCard(
            context,
            title: 'Good Options',
            subtitle: 'Manage Good calculation options',
            icon: Icons.check_circle_outline,
            onAdd: () => _showAddGoodOptionDialog(context, settingsProvider),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              children: settingsProvider.goodOptions.map((opt) {
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        opt.value,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: opt.enabled ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        opt.enabled ? '(Enabled)' : '(Disabled)',
                        style: TextStyle(
                          fontSize: 10,
                          color: opt.enabled ? theme.colorScheme.onPrimary.withAlpha(200) : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  selected: opt.enabled,
                  selectedColor: Colors.green.shade700,
                  checkmarkColor: Colors.white,
                  onSelected: (val) {
                    settingsProvider.toggleGoodOption(opt.value, val);
                  },
                  onDeleted: () => _confirmRemoveGoodOption(context, settingsProvider, opt.value),
                  deleteIcon: Icon(
                    Icons.close,
                    size: 16,
                    color: opt.enabled ? Colors.white : theme.colorScheme.onSurfaceVariant,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 5. Rejection Options Management Card
          _buildConfigurationCard(
            context,
            title: 'Rejection Options',
            subtitle: 'Manage Rejection calculation options',
            icon: Icons.cancel_outlined,
            onAdd: () => _showAddRejectionOptionDialog(context, settingsProvider),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: settingsProvider.rejectionOptions.map((opt) {
                return Chip(
                  label: Text(opt, style: const TextStyle(fontWeight: FontWeight.bold)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _confirmRemoveRejectionOption(context, settingsProvider, opt),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 6. Q.C Constant Management Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(Icons.verified_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Q.C',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Change Q.C constant value used globally in calculations',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Current Q.C Constant: ${settingsProvider.qcConstant.truncateToDouble() == settingsProvider.qcConstant ? settingsProvider.qcConstant.toInt() : settingsProvider.qcConstant}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showEditQCDialog(context, settingsProvider),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Change Value'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Appearance Settings Group
          Text(
            'Appearance',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          // Theme Toggle Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(Icons.brightness_6_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Switch application visual style between Light and Dark mode',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '☀ Light',
                        style: TextStyle(
                          fontWeight: !settingsProvider.isDarkMode ? FontWeight.bold : FontWeight.normal,
                          color: !settingsProvider.isDarkMode ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: settingsProvider.isDarkMode,
                        onChanged: (val) {
                          settingsProvider.setDarkMode(val);
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Dark 🌙',
                        style: TextStyle(
                          fontWeight: settingsProvider.isDarkMode ? FontWeight.bold : FontWeight.normal,
                          color: settingsProvider.isDarkMode ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Export Settings Group
          Text(
            'Export Settings',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          // Save Location Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.folder_special_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Save Location',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configured folder for saving generated Excel (.xlsx) reports',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Display Effective Location
                  FutureBuilder<String>(
                    future: settingsProvider.getEffectiveSaveLocation(),
                    builder: (context, snapshot) {
                      final displayPath = snapshot.data ?? 'Resolving location...';
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: SelectableText(
                          displayPath,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Change Location Action Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (settingsProvider.customSaveLocation != null)
                        TextButton.icon(
                          onPressed: () {
                            settingsProvider.setExportSaveLocation(null);
                          },
                          icon: const Icon(Icons.restore_rounded, size: 18),
                          label: const Text('Reset to Default Downloads'),
                        )
                      else
                        const SizedBox(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _handleChangeLocation(context, settingsProvider),
                        icon: const Icon(Icons.drive_file_move_outlined, size: 20),
                        label: const Text('Change Location'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Automatic Export Toggle Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(Icons.bolt_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Automatic Export',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Automatically generate filename and save XLSX without file pickers',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: settingsProvider.automaticExport,
                    onChanged: (val) {
                      settingsProvider.setAutomaticExport(val);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onAdd,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  // --- DIALOGS FOR MACHINE MANAGEMENT ---
  void _showAddMachineDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Machine Series'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Machine Series Name (e.g. D1, M3)',
                errorText: errorText,
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final input = controller.text.trim().toUpperCase();
                  if (input.isEmpty) {
                    setState(() => errorText = 'Please enter a machine name');
                    return;
                  }
                  final success = await settings.addMachine(input);
                  if (!success) {
                    setState(() => errorText = 'Machine "$input" already exists');
                    return;
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmRemoveMachine(BuildContext context, SettingsProvider settings, String machine) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Removal'),
        content: Text('Are you sure you want to remove Machine $machine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await settings.removeMachine(machine);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // --- DIALOGS FOR PRODUCT CODE MANAGEMENT ---
  void _showAddProductCodeDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Product Code'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Product Code (e.g. N60PM)',
                errorText: errorText,
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final input = controller.text.trim().toUpperCase();
                  if (input.isEmpty) {
                    setState(() => errorText = 'Please enter a product code');
                    return;
                  }
                  final success = await settings.addProductCode(input);
                  if (!success) {
                    setState(() => errorText = 'Product Code "$input" already exists');
                    return;
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmRemoveProductCode(BuildContext context, SettingsProvider settings, String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Removal'),
        content: Text('Are you sure you want to remove Product Code $code?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await settings.removeProductCode(code);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // --- DIALOGS FOR PLANT MANAGEMENT ---
  void _showAddPlantDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Plant'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Plant Name (e.g. H, PLANT-1)',
                errorText: errorText,
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final input = controller.text.trim().toUpperCase();
                  if (input.isEmpty) {
                    setState(() => errorText = 'Please enter a plant name');
                    return;
                  }
                  final success = await settings.addPlant(input);
                  if (!success) {
                    setState(() => errorText = 'Plant "$input" already exists');
                    return;
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmRemovePlant(BuildContext context, SettingsProvider settings, String plant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Removal'),
        content: Text('Are you sure you want to remove Plant $plant?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await settings.removePlant(plant);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // --- DIALOGS FOR GOOD OPTIONS MANAGEMENT ---
  void _showAddGoodOptionDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Good Option'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Good Option Value (e.g. 0.2, 0.5, CSTM)',
                errorText: errorText,
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final input = controller.text.trim().toUpperCase();
                  if (input.isEmpty) {
                    setState(() => errorText = 'Please enter a value');
                    return;
                  }
                  if (input != 'CSTM' && double.tryParse(input) == null) {
                    setState(() => errorText = 'Enter a valid numeric value or "CSTM"');
                    return;
                  }
                  final success = await settings.addGoodOption(input);
                  if (!success) {
                    setState(() => errorText = 'Good Option "$input" already exists');
                    return;
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmRemoveGoodOption(BuildContext context, SettingsProvider settings, String option) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Removal'),
        content: Text('Are you sure you want to remove Good Option $option?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await settings.removeGoodOption(option);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // --- DIALOGS FOR REJECTION OPTIONS MANAGEMENT ---
  void _showAddRejectionOptionDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Rejection Option'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Rejection Value (e.g. 4.2, 5, CSTM)',
                errorText: errorText,
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final input = controller.text.trim().toUpperCase();
                  if (input.isEmpty) {
                    setState(() => errorText = 'Please enter a value');
                    return;
                  }
                  if (input != 'CSTM' && double.tryParse(input) == null) {
                    setState(() => errorText = 'Enter a valid numeric value or "CSTM"');
                    return;
                  }
                  final success = await settings.addRejectionOption(input);
                  if (!success) {
                    setState(() => errorText = 'Rejection Option "$input" already exists');
                    return;
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmRemoveRejectionOption(BuildContext context, SettingsProvider settings, String option) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Removal'),
        content: Text('Are you sure you want to remove Rejection Option $option?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await settings.removeRejectionOption(option);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // --- DIALOG FOR Q.C CONSTANT MANAGEMENT ---
  void _showEditQCDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(
      text: settings.qcConstant.truncateToDouble() == settings.qcConstant
          ? settings.qcConstant.toInt().toString()
          : settings.qcConstant.toString(),
    );
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Change Q.C Constant'),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Q.C Constant Value (e.g. 95, 100)',
                errorText: errorText,
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final input = controller.text.trim();
                  final val = double.tryParse(input);
                  if (val == null || val <= 0) {
                    setState(() => errorText = 'Please enter a valid number greater than 0');
                    return;
                  }
                  await settings.setQCConstant(val);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleChangeLocation(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) async {
    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.blue, size: 28),
              SizedBox(width: 8),
              Text('Web File Downloads'),
            ],
          ),
          content: const Text(
            'In Web browsers, exported Excel (.xlsx) files are automatically downloaded directly to your computer or phone\'s default Downloads directory according to browser security standards.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Export Folder Location',
      );

      if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
        await settingsProvider.setExportSaveLocation(selectedDirectory);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Save location updated to:\n$selectedDirectory'),
              backgroundColor: Colors.teal,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select directory: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
