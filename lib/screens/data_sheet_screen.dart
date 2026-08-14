// Dedicated Data Sheet Screen displaying production database records with edit, delete, delete all, and automatic shift-based XLSX export.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/production.dart';
import '../providers/production_provider.dart';
import '../providers/settings_provider.dart';
import '../services/excel_service.dart';
import '../widgets/production_table.dart';

class DataSheetScreen extends StatelessWidget {
  final ValueChanged<Production>? onEditProduction;

  const DataSheetScreen({
    super.key,
    this.onEditProduction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prodProvider = Provider.of<ProductionProvider>(context);
    final records = prodProvider.records;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header with Excel Import / Export & Delete All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Production Data Sheet',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View, edit, delete, and export saved production records',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _handleImportExcel(context, prodProvider),
                    icon: const Icon(Icons.file_upload_outlined),
                    label: const Text('Import Excel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: records.isEmpty
                        ? null
                        : () => _showExportShiftDialog(context, records),
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Export Excel'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: records.isEmpty
                        ? null
                        : () => _confirmDeleteAll(context, prodProvider, records.length),
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Delete All'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Records Count Header
          Text(
            'Saved Production Rows (${records.length} entries)',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Production Table
          ProductionTable(
            records: records,
            onEdit: (rec) {
              onEditProduction?.call(rec);
            },
            onDelete: (rec) {
              if (rec.id != null) {
                prodProvider.deleteProduction(rec.id!);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showExportShiftDialog(BuildContext context, List<Production> records) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Center(
          child: Text(
            'Choose your shift',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _executeAutomaticExport(context, records, 'First');
                  },
                  child: const Text('First', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _executeAutomaticExport(context, records, 'Second');
                  },
                  child: const Text('Second', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _executeAutomaticExport(context, records, 'Night');
                  },
                  child: const Text('Night', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeAutomaticExport(
    BuildContext context,
    List<Production> records,
    String shift,
  ) async {
    try {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final customSaveLocation = settingsProvider.customSaveLocation;

      final exportPath = await ExcelService.exportProductionData(
        shift: shift,
        date: DateTime.now(),
        records: records,
        targetDirectory: customSaveLocation,
      );

      final fullPath = exportPath ?? 'Downloads';
      final fileName = fullPath.contains('/') || fullPath.contains('\\')
          ? fullPath.split(RegExp(r'[/\\]')).last
          : fullPath;

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.teal, size: 28),
                SizedBox(width: 8),
                Text('Production Data Exported'),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('File saved as:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  SelectableText(
                    fileName,
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  const Text('Location:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  SelectableText(
                    fullPath,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text('Export Location Unavailable'),
              ],
            ),
            content: Text('Unable to save export file:\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _confirmDeleteAll(
    BuildContext context,
    ProductionProvider prodProvider,
    int count,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Delete All Production Records?'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete all $count production records from the database?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await prodProvider.deleteAllProductions();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All production records deleted successfully.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImportExcel(
    BuildContext context,
    ProductionProvider prodProvider,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        final fileName = file.name;
        final bytes = file.bytes;

        if (bytes != null) {
          final importResult = await prodProvider.importExcel(bytes, fileName: fileName);

          if (importResult.validRecords.isNotEmpty) {
            if (context.mounted) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully imported ${importResult.validRecords.length} records.'),
                  backgroundColor: Colors.teal,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import Excel file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
