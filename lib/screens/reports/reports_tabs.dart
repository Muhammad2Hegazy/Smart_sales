import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'sales/sales_reports_tab.dart';
import 'warehouses/warehouses_reports_tab.dart';
import 'accounts/accounts_reports_tab.dart';

class ReportsTabs extends StatefulWidget {
  const ReportsTabs({super.key});

  @override
  State<ReportsTabs> createState() => _ReportsTabsState();
}

class _ReportsTabsState extends State<ReportsTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.reports),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.shopping_cart),
              text: l10n.sales,
            ),
            Tab(
              icon: const Icon(Icons.warehouse),
              text: l10n.warehouses,
            ),
            Tab(
              icon: const Icon(Icons.account_balance),
              text: l10n.accounts,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SalesReportsTab(),
          WarehousesReportsTab(),
          AccountsReportsTab(),
        ],
      ),
    );
  }
}

