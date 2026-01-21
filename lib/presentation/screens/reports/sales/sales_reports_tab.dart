import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/database/database_helper.dart';
import '../../../blocs/device/device_bloc.dart';
import '../../../blocs/device/device_state.dart';
import 'shift_close_report.dart';
import 'category_sales_report.dart';
import 'item_sales_report.dart';
import 'consolidated_sales_report.dart';

class SalesReportsTab extends StatefulWidget {
  const SalesReportsTab({super.key});

  @override
  State<SalesReportsTab> createState() => _SalesReportsTabState();
}

class _SalesReportsTabState extends State<SalesReportsTab> with TickerProviderStateMixin {
  TabController? _floorTabController;
  int? _selectedFloor;
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
                  _selectedFloor = null; // All floors
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
    return BlocBuilder<DeviceBloc, DeviceState>(
      builder: (context, deviceState) {
        final currentDevice = deviceState is DeviceReady ? deviceState.currentDevice : null;
        final isMasterDevice = currentDevice?.floor == 2;

        return _buildContent(context, isMasterDevice, currentDevice?.floor);
      },
    );
  }

  Widget _buildContent(BuildContext context, bool isMasterDevice, int? currentFloor) {
    final l10n = AppLocalizations.of(context)!;

    // If not master device, restrict to current floor
    final effectiveSelectedFloor = isMasterDevice ? _selectedFloor : (currentFloor ?? _selectedFloor);

    final salesReports = [
      {
        'title': l10n.shiftClosingReport,
        'icon': Icons.access_time,
        'onTap': () => ShiftCloseReport.show(context, effectiveSelectedFloor),
      },
      {
        'title': l10n.salesReportByCategory,
        'icon': Icons.category,
        'onTap': () => CategorySalesReport.show(context, effectiveSelectedFloor),
      },
      {
        'title': l10n.salesReportByItem,
        'icon': Icons.inventory_2,
        'onTap': () => ItemSalesReport.show(context, effectiveSelectedFloor),
      },
      {
        'title': l10n.consolidatedSalesReport,
        'icon': Icons.summarize,
        'onTap': () => ConsolidatedSalesReport.show(context, effectiveSelectedFloor),
      },
    ];

    if (_isLoading || _floorTabController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Floor sub-tabs - Only show if master device
        if (isMasterDevice)
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _floorTabController!,
              isScrollable: true,
              tabs: [
                Tab(text: l10n.all),
                ..._availableFloors.map((floor) {
                  String floorName;
                  if (floor == 1) {
                    floorName = l10n.groundFloor;
                  } else if (floor == 2) {
                    floorName = l10n.secondFloor;
                  } else if (floor == 3) {
                    floorName = l10n.thirdFloor;
                  } else {
                    floorName = '${l10n.floor} $floor';
                  }
                  return Tab(text: floorName);
                }),
              ],
            ),
          )
        else if (currentFloor != null)
           Container(
            color: AppColors.surface,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
            child: Text(
              '${l10n.floor}: ${currentFloor == 1 ? l10n.groundFloor : currentFloor == 2 ? l10n.secondFloor : currentFloor == 3 ? l10n.thirdFloor : currentFloor}',
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
            ),
          ),
        // Reports list
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ListView.builder(
              itemCount: salesReports.length,
              itemBuilder: (context, index) {
                final report = salesReports[index];
                return AppCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ListTile(
                    leading: Icon(
                      report['icon'] as IconData,
                      color: AppColors.primary,
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
