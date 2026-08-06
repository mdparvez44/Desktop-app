/// Screen displaying the Daily Report with Machine Series, Plant Wise, and Product Code Wise view modes and WhatsApp Report Sharing.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/daily_report.dart';
import '../models/production.dart';
import '../providers/production_provider.dart';
import '../services/calculation_service.dart';
import '../services/excel_service.dart';
import '../services/report_formatter_service.dart';
import '../utils/formatters.dart';
import '../utils/truncate_utils.dart';

enum DailyReportViewMode {
  machineSeries,
  plantWise,
  productCodeWise,
}

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  DailyReportViewMode _viewMode = DailyReportViewMode.machineSeries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prodProvider = Provider.of<ProductionProvider>(context);
    final records = prodProvider.records;

    final machineSummary = CalculationService.computeDailyReportSummary(records);
    final plantWiseRows = CalculationService.computePlantWiseDailyReport(records);
    final productWiseRows = CalculationService.computeProductWiseDailyReport(records);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action & View Switcher Bar
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // View Switcher Buttons
              SegmentedButton<DailyReportViewMode>(
                segments: const [
                  ButtonSegment(
                    value: DailyReportViewMode.machineSeries,
                    label: Text('Machine Series'),
                    icon: Icon(Icons.precision_manufacturing_outlined),
                  ),
                  ButtonSegment(
                    value: DailyReportViewMode.plantWise,
                    label: Text('Plant Wise'),
                    icon: Icon(Icons.factory_outlined),
                  ),
                  ButtonSegment(
                    value: DailyReportViewMode.productCodeWise,
                    label: Text('Product Code Wise'),
                    icon: Icon(Icons.category_outlined),
                  ),
                ],
                selected: {_viewMode},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _viewMode = newSelection.first;
                  });
                },
              ),

              // Refresh Button
              OutlinedButton.icon(
                onPressed: () => prodProvider.loadProductions(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),

              // Export Excel Button
              ElevatedButton.icon(
                onPressed: machineSummary.rows.isEmpty
                    ? null
                    : () => _exportDailyReport(context, machineSummary),
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('Export Excel'),
              ),

              // Generate WhatsApp Report Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: records.isEmpty
                    ? null
                    : () => _showWhatsAppReportDialog(
                          context,
                          records: records,
                          date: DateTime.now(),
                          shift: 'Second',
                        ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Generate WhatsApp Report'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Daily Report Data Table taking remaining full height
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No production data available.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _buildTableForActiveView(
                            theme: theme,
                            machineSummary: machineSummary,
                            plantWiseRows: plantWiseRows,
                            productWiseRows: productWiseRows,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableForActiveView({
    required ThemeData theme,
    required DailyReportSummary machineSummary,
    required List<PlantWiseDailyReportRow> plantWiseRows,
    required List<ProductWiseDailyReportRow> productWiseRows,
  }) {
    switch (_viewMode) {
      case DailyReportViewMode.plantWise:
        return _buildPlantWiseTable(theme, plantWiseRows);
      case DailyReportViewMode.productCodeWise:
        return _buildProductWiseTable(theme, productWiseRows);
      case DailyReportViewMode.machineSeries:
        return _buildMachineSeriesTable(theme, machineSummary);
    }
  }

  Widget _buildMachineSeriesTable(ThemeData theme, DailyReportSummary summary) {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        theme.colorScheme.surfaceContainerHigh,
      ),
      dataRowMinHeight: 48,
      dataRowMaxHeight: 56,
      columnSpacing: 24,
      columns: const [
        DataColumn(label: Text('Machine Series', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Product Code', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Tested Gross', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
        DataColumn(label: Text('Good Gross', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
        DataColumn(label: Text('Rejection Gross', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
        DataColumn(label: Text('Hold', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
        DataColumn(label: Text('Q.C', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
        DataColumn(label: Text('Rejection Percentage', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
      ],
      rows: [
        ...summary.rows.map((r) {
          return DataRow(
            cells: [
              DataCell(Text(r.machine, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(r.productCode, style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text(AppFormatters.formatNumber(r.testedGross))),
              DataCell(Text(AppFormatters.formatNumber(r.goodGross))),
              DataCell(Text(AppFormatters.formatNumber(r.rejectionGross))),
              const DataCell(Text('')), // Hold is left completely blank
              DataCell(Text(AppFormatters.formatNumber(r.totalQCGross))),
              DataCell(Text('${AppFormatters.formatNumber(r.rejectionPercentage)}%')),
            ],
          );
        }),

        // Bottom Totals Row
        DataRow(
          color: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHigh),
          cells: [
            const DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            const DataCell(Text('')),
            DataCell(Text(
              AppFormatters.formatNumber(summary.totalTestedGross),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            )),
            DataCell(Text(
              AppFormatters.formatNumber(summary.totalGoodGross),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            )),
            DataCell(Text(
              AppFormatters.formatNumber(summary.totalRejectionGross),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            )),
            const DataCell(Text('')),
            DataCell(Text(
              AppFormatters.formatNumber(summary.totalQCGross),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            )),
            DataCell(Text(
              '${AppFormatters.formatNumber(summary.totalRejectionPercentage)}%',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildPlantWiseTable(ThemeData theme, List<PlantWiseDailyReportRow> rows) {
    double totalTested = rows.fold(0.0, (s, r) => truncateTo2(s + r.testedGross));
    double totalGood = rows.fold(0.0, (s, r) => truncateTo2(s + r.goodGross));
    double totalReject = rows.fold(0.0, (s, r) => truncateTo2(s + r.rejectionGross));
    double totalQC = rows.fold(0.0, (s, r) => truncateTo2(s + r.totalQCGross));
    double totalRejPct = totalTested > 0 ? truncateTo2((totalReject / totalTested) * 100.0) : 0.0;

    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        theme.colorScheme.surfaceContainerHigh,
      ),
      dataRowMinHeight: 48,
      dataRowMaxHeight: 56,
      columnSpacing: 24,
      columns: const [
        DataColumn(label: Text('Plant', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Product Code', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Tested Gross', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
        DataColumn(label: Text('Good Gross', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
        DataColumn(label: Text('Rejection Gross', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
        DataColumn(label: Text('Q.C Gross', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
        DataColumn(label: Text('Rejection Percentage', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
      ],
      rows: [
        ...rows.map((r) {
          return DataRow(
            cells: [
              DataCell(Text(r.plant, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(r.productCode, style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text(AppFormatters.formatNumber(r.testedGross))),
              DataCell(Text(AppFormatters.formatNumber(r.goodGross))),
              DataCell(Text(AppFormatters.formatNumber(r.rejectionGross))),
              DataCell(Text(AppFormatters.formatNumber(r.totalQCGross))),
              DataCell(Text('${AppFormatters.formatNumber(r.rejectionPercentage)}%')),
            ],
          );
        }),

        // Totals Row
        DataRow(
          color: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHigh),
          cells: [
            const DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            const DataCell(Text('')),
            DataCell(Text(
              AppFormatters.formatNumber(totalTested),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            )),
            DataCell(Text(
              AppFormatters.formatNumber(totalGood),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            )),
            DataCell(Text(
              AppFormatters.formatNumber(totalReject),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            )),
            DataCell(Text(
              AppFormatters.formatNumber(totalQC),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            )),
            DataCell(Text(
              '${AppFormatters.formatNumber(totalRejPct)}%',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildProductWiseTable(ThemeData theme, List<ProductWiseDailyReportRow> rows) {
    double totalTested = rows.fold(0.0, (s, r) => truncateTo2(s + r.testedGross));
    double totalGood = rows.fold(0.0, (s, r) => truncateTo2(s + r.goodGross));
    double totalReject = rows.fold(0.0, (s, r) => truncateTo2(s + r.rejectionGross));
    double totalQC = rows.fold(0.0, (s, r) => truncateTo2(s + r.totalQCGross));
    double totalRejPct = totalTested > 0 ? truncateTo2((totalReject / totalTested) * 100.0) : 0.0;

    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        theme.colorScheme.surfaceContainerHigh,
      ),
      dataRowMinHeight: 48,
      dataRowMaxHeight: 56,
      columnSpacing: 24,
      columns: const [
        DataColumn(label: Text('Product Code', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Tested Gross', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
        DataColumn(label: Text('Good Gross', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
        DataColumn(label: Text('Rejection Gross', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
        DataColumn(label: Text('Q.C Gross', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
        DataColumn(label: Text('Rejection Percentage', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
      ],
      rows: [
        ...rows.map((r) {
          return DataRow(
            cells: [
              DataCell(Text(r.productCode, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(AppFormatters.formatNumber(r.testedGross))),
              DataCell(Text(AppFormatters.formatNumber(r.goodGross))),
              DataCell(Text(AppFormatters.formatNumber(r.rejectionGross))),
              DataCell(Text(AppFormatters.formatNumber(r.totalQCGross))),
              DataCell(Text('${AppFormatters.formatNumber(r.rejectionPercentage)}%')),
            ],
          );
        }),

        // Totals Row
        DataRow(
          color: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHigh),
          cells: [
            const DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            DataCell(Text(
              AppFormatters.formatNumber(totalTested),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            )),
            DataCell(Text(
              AppFormatters.formatNumber(totalGood),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            )),
            DataCell(Text(
              AppFormatters.formatNumber(totalReject),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            )),
            DataCell(Text(
              AppFormatters.formatNumber(totalQC),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            )),
            DataCell(Text(
              '${AppFormatters.formatNumber(totalRejPct)}%',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red),
            )),
          ],
        ),
      ],
    );
  }

  void _showWhatsAppReportDialog(
    BuildContext context, {
    required List<Production> records,
    required DateTime date,
    required String shift,
  }) {
    String selectedShift = shift;
    int binHoldCount = 2;
    final reworkController = TextEditingController(
      text: 'D1 - Bubble with leak on T.A\nE1 - Leak on B.B',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final reworkItems = reworkController.text
                .split('\n')
                .where((s) => s.trim().isNotEmpty)
                .toList();

            final reportText = ReportFormatterService.generateWhatsAppReport(
              records: records,
              date: date,
              shift: selectedShift,
              binHoldCount: binHoldCount,
              reworkDetails: reworkItems,
            );

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.chat_bubble, color: Colors.green),
                  SizedBox(width: 8),
                  Text('WhatsApp Formatted Report'),
                ],
              ),
              content: SizedBox(
                width: 540,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Shift: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: selectedShift,
                            underline: const SizedBox(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => selectedShift = val);
                              }
                            },
                            items: ['First', 'Second', 'Night'].map((s) {
                              return DropdownMenuItem(value: s, child: Text(s));
                            }).toList(),
                          ),
                          const Spacer(),
                          const Text('Hold Bins: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              decoration: const InputDecoration(isDense: true),
                              keyboardType: TextInputType.number,
                              controller: TextEditingController(text: '$binHoldCount'),
                              onChanged: (val) {
                                final parsed = int.tryParse(val);
                                if (parsed != null) {
                                  setState(() => binHoldCount = parsed);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Rework / Hold Reasons (One per line):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: reworkController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'e.g. D1 - Bubble with leak on T.A\nE1 - Leak on B.B',
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      const Text('Live Preview:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: SelectableText(
                          reportText,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: reportText));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('WhatsApp report copied to clipboard!'),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy to Clipboard'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportDailyReport(BuildContext context, DailyReportSummary summary) async {
    try {
      final now = DateTime.now();
      final downloadsPath = await ExcelService.getDownloadsDirectoryPath();
      final baseName = 'DailyReport_${now.day}-${now.month}-${now.year}';
      String targetPath = '$downloadsPath${Platform.pathSeparator}$baseName.xlsx';
      File targetFile = File(targetPath);

      int counter = 1;
      while (targetFile.existsSync()) {
        targetPath = '$downloadsPath${Platform.pathSeparator}$baseName ($counter).xlsx';
        targetFile = File(targetPath);
        counter++;
      }

      final bytes = ExcelService.exportDailyReportToBytes(summary, now);
      if (bytes != null) {
        await targetFile.writeAsBytes(bytes);
        final fileName = targetPath.split(Platform.pathSeparator).last;

        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.teal, size: 28),
                  SizedBox(width: 8),
                  Text('Daily Report Exported'),
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
                      targetPath,
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
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export Daily Report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
