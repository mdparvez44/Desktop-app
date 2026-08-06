/// Machine-Wise Gross Screen displaying Tested Quantity and Tested Gross for all 26 machine series (A1..M2).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/production_provider.dart';
import '../services/calculation_service.dart';
import '../utils/formatters.dart';

class GrossScreen extends StatelessWidget {
  const GrossScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prodProvider = Provider.of<ProductionProvider>(context);
    final records = prodProvider.records;

    final summary = CalculationService.computeMachineGrossReport(records);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Machine-Wise Gross',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Machine-wise Total Tested Quantity and Total Tested Gross across all 26 machine series (A1..M2)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Machine Gross Table Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    theme.colorScheme.surfaceContainerHigh,
                  ),
                  columnSpacing: 40,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Machine Series',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      numeric: true,
                      label: Text(
                        'Total Tested',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      numeric: true,
                      label: Text(
                        'Total Tested Gross',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: [
                    ...summary.rows.map((row) {
                      final hasData = row.totalTested > 0;
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              row.machine,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: hasData
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant.withAlpha(128),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              AppFormatters.formatNumber(row.totalTested),
                              style: TextStyle(
                                fontWeight: hasData ? FontWeight.bold : FontWeight.normal,
                                color: hasData
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant.withAlpha(128),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              AppFormatters.formatGross(row.totalTestedGross),
                              style: TextStyle(
                                fontWeight: hasData ? FontWeight.bold : FontWeight.normal,
                                color: hasData
                                    ? Colors.teal.shade800
                                    : theme.colorScheme.onSurfaceVariant.withAlpha(128),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),

                    // OVERALL TOTAL FOOTER ROW
                    DataRow(
                      color: WidgetStateProperty.all(
                        theme.colorScheme.primaryContainer,
                      ),
                      cells: [
                        const DataCell(
                          Text(
                            'OVERALL TOTAL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            AppFormatters.formatNumber(summary.overallTotalTested),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            AppFormatters.formatGross(summary.overallTestedGross),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
