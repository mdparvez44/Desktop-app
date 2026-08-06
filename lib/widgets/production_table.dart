/// Desktop data table for production records.
library;

import 'package:flutter/material.dart';
import '../models/production.dart';
import '../utils/formatters.dart';

class ProductionTable extends StatelessWidget {
  final List<Production> records;
  final ValueChanged<Production> onEdit;
  final ValueChanged<Production> onDelete;

  const ProductionTable({
    super.key,
    required this.records,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open_outlined,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
              ),
              const SizedBox(height: 16),
              Text(
                'No production records found',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add records using the Input Entry screen',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              theme.colorScheme.surfaceContainerHigh,
            ),
            dataRowMinHeight: 48,
            dataRowMaxHeight: 56,
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('M.No', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Plant', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Product Code', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Good', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Rej', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Q.C', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Samples', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Tested', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: records.map((p) {
              return DataRow(
                cells: [
                  DataCell(Text(
                    p.machine,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )),
                  DataCell(Text(p.plant)),
                  DataCell(Text(
                    p.productCode,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  )),
                  DataCell(Text(AppFormatters.formatNumber(p.good))),
                  DataCell(Text(AppFormatters.formatNumber(p.reject))),
                  DataCell(Text(AppFormatters.formatNumber(p.qa))),
                  DataCell(Text(AppFormatters.formatNumber(p.sample))),
                  DataCell(Text(
                    AppFormatters.formatNumber(p.tested),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'Edit Record',
                        color: Colors.blue.shade700,
                        onPressed: () => onEdit(p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        tooltip: 'Delete Record',
                        color: Colors.red.shade700,
                        onPressed: () => _confirmDelete(context, p),
                      ),
                    ],
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Production record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Production Record?'),
        content: Text(
          'Are you sure you want to delete production entry for Machine ${record.machine} (${record.productCode})?\n\nThis operation cannot be undone.',
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
            onPressed: () {
              Navigator.pop(ctx);
              onDelete(record);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
