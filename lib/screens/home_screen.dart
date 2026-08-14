/// Main Desktop & Mobile Responsive Container Screen organizing navigation for ET Calculator screens.
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

  String _getScreenTitle(int index) {
    switch (index) {
      case 0:
        return 'Input Entry Sheet';
      case 1:
        return 'Production Data Sheet';
      case 2:
        return 'Reports';
      case 3:
        return 'Gross Summary';
      case 4:
        return 'Daily Report';
      case 5:
        return 'Settings';
      default:
        return 'ET Calculator';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _getScreenTitle(_selectedIndex),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _selectedIndex == 5 ? Icons.settings : Icons.settings_outlined,
              ),
              tooltip: 'Settings',
              onPressed: () => _navigateToIndex(5),
            ),
          ],
        ),
        body: IndexedStack(
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
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
          onDestinationSelected: _navigateToIndex,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.edit_note_outlined),
              selectedIcon: Icon(Icons.edit_note),
              label: 'Input',
            ),
            NavigationDestination(
              icon: Icon(Icons.table_chart_outlined),
              selectedIcon: Icon(Icons.table_chart),
              label: 'Data',
            ),
            NavigationDestination(
              icon: Icon(Icons.assessment_outlined),
              selectedIcon: Icon(Icons.assessment),
              label: 'Reports',
            ),
            NavigationDestination(
              icon: Icon(Icons.calculate_outlined),
              selectedIcon: Icon(Icons.calculate),
              label: 'Gross',
            ),
            NavigationDestination(
              icon: Icon(Icons.today_outlined),
              selectedIcon: Icon(Icons.today),
              label: 'Daily',
            ),
          ],
        ),
      );
    }

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
