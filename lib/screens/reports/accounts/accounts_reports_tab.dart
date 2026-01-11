import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/database/database_helper.dart';

class AccountsReportsTab extends StatefulWidget {
  const AccountsReportsTab({super.key});

  @override
  State<AccountsReportsTab> createState() => _AccountsReportsTabState();
}

class _AccountsReportsTabState extends State<AccountsReportsTab> with TickerProviderStateMixin {
  TabController? _floorTabController;
  // ignore: unused_field
  int? _selectedFloor; // Will be used when reports are implemented
  List<int> _availableFloors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFloors();
  }

  @override
  void dispose() {
    _floorTabController?.dispose();
    super.dispose();
  }

  Future<void> _loadFloors() async {
    try {
      final dbHelper = DatabaseHelper();
      final allDevices = await dbHelper.getAllDevices();
      
      final floors = <int>{};
      for (var device in allDevices) {
        if (device.floor != null) {
          floors.add(device.floor!);
        }
      }
      
      final sortedFloors = floors.toList()..sort();
      
      if (mounted) {
        setState(() {
          _availableFloors = sortedFloors;
          final floorTabLength = sortedFloors.isEmpty ? 1 : sortedFloors.length + 1;
          _floorTabController?.dispose();
          _floorTabController = TabController(length: floorTabLength, vsync: this);
          
          _floorTabController!.addListener(() {
            if (!_floorTabController!.indexIsChanging && mounted) {
              setState(() {
                if (_floorTabController!.index == 0) {
                  _selectedFloor = null;
                } else {
                  _selectedFloor = _availableFloors[_floorTabController!.index - 1];
                }
              });
            }
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final accountsReports = [
      {
        'title': l10n.customerAccountStatement,
        'icon': Icons.description,
        'onTap': () {},
      },
      {
        'title': l10n.customerBalancesReport,
        'icon': Icons.account_balance_wallet,
        'onTap': () {},
      },
      {
        'title': l10n.supplierAccountStatement,
        'icon': Icons.receipt_long,
        'onTap': () {},
      },
      {
        'title': l10n.supplierBalancesReport,
        'icon': Icons.balance,
        'onTap': () {},
      },
      {
        'title': l10n.generalLedgerReport,
        'icon': Icons.book,
        'onTap': () {},
      },
      {
        'title': l10n.accountBalancesReport,
        'icon': Icons.account_balance,
        'onTap': () {},
      },
      {
        'title': l10n.incomeStatementReport,
        'icon': Icons.trending_up,
        'onTap': () {},
      },
      {
        'title': l10n.profitReportForPeriod,
        'icon': Icons.attach_money,
        'onTap': () {},
      },
    ];

    if (_isLoading || _floorTabController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _floorTabController!,
            isScrollable: true,
            tabs: [
              Tab(text: l10n.all),
              ..._availableFloors.map((floor) {
                String floorName;
                if (floor == 0) {
                  floorName = l10n.groundFloor; // مرسى
                } else if (floor == 2) {
                  floorName = l10n.secondFloor; // دور 2
                } else if (floor == 3) {
                  floorName = l10n.thirdFloor; // دور 3
                } else {
                  floorName = '${l10n.floor} $floor';
                }
                return Tab(text: floorName);
              }),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ListView.builder(
              itemCount: accountsReports.length,
              itemBuilder: (context, index) {
                final report = accountsReports[index];
                return AppCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ListTile(
                    leading: Icon(
                      report['icon'] as IconData,
                      color: AppColors.accent,
                      size: 28,
                    ),
                    title: Text(
                      report['title'] as String,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    onTap: report['onTap'] as VoidCallback,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

