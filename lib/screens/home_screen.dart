/// Main Desktop Container Screen organizing sidebar navigation for ET Calculator screens.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/production.dart';
import '../providers/production_provider.dart';
import '../widgets/desktop_sidebar.dart';
import 'daily_report_screen.dart';
import 'data_sheet_screen.dart';
import 'gross_screen.dart';
import 'input_sheet_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _previousIndex = 0;
  Production? _editingRecord;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductionProvider>(context, listen: false).loadProductions();
    });
  }

  void _navigateToIndex(int index) {
    setState(() {
      if (index != 5) {
        _previousIndex = index;
      }
      _selectedIndex = index;
    });
  }

  void _editProduction(Production record) {
    setState(() {
      _editingRecord = record;
      _selectedIndex = 0; // Navigate to Input Entry Sheet
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Desktop Sidebar / Navigation Rail
          DesktopSidebar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _navigateToIndex,
          ),

          // Main View Content Area
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                InputSheetScreen(
                  editingRecord: _editingRecord,
                  onClearEditing: () => setState(() => _editingRecord = null),
                ),
                DataSheetScreen(
                  onEditProduction: _editProduction,
                ),
                const ReportScreen(),
                const GrossScreen(),
                const DailyReportScreen(),
                SettingsScreen(
                  onBack: () => setState(() => _selectedIndex = _previousIndex),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
