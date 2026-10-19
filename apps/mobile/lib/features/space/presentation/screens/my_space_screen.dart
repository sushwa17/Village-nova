import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:villagenova/core/theme/app_colors.dart';
import 'package:villagenova/widgets/stitch_card.dart';
import 'package:villagenova/widgets/stitch_button.dart';
import 'package:villagenova/providers/farm_provider.dart';
import 'package:villagenova/models/farm_model.dart';

class MySpaceScreen extends ConsumerStatefulWidget {
  const MySpaceScreen({super.key});

  @override
  ConsumerState<MySpaceScreen> createState() => _MySpaceScreenState();
}

class _MySpaceScreenState extends ConsumerState<MySpaceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(farmProvider.notifier).fetchMyFarm();
    });
  }

  @override
  Widget build(BuildContext context) {
    final farmState = ref.watch(farmProvider);
    final farm = farmState.farm;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'My Farm & Crop Space',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Farm Data',
            onPressed: () => ref.read(farmProvider.notifier).fetchMyFarm(),
          ),
        ],
      ),
      body: farmState.status == FarmStatus.loading && farm == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: () => ref.read(farmProvider.notifier).fetchMyFarm(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (farm != null) ...[
                      // 1. Farm Profile Header Card
                      _buildFarmHeaderCard(farm),
                      const SizedBox(height: 16),

                      // 2. Weather Advisory & Alert
                      _buildAdvisoryCard(farm),
                      const SizedBox(height: 16),

                      // 3. Active Crop & Sowing Progress Card
                      if (farm.crop != null) ...[
                        _buildActiveCropCard(farm.crop!),
                        const SizedBox(height: 16),

                        // 4. Visual Agronomic Timeline Stepper
                        _buildCropStageStepper(farm.crop!),
                        const SizedBox(height: 16),
                      ],

                      // 5. Quick Farm Action Buttons
                      _buildQuickActionRow(context),
                      const SizedBox(height: 16),

                      // 6. Recent Activities Log
                      _buildRecentActivitiesCard(farm),
                      const SizedBox(height: 16),

                      // 7. Expenses & Financial Breakdown
                      _buildFinancialSummaryCard(farm),
                      const SizedBox(height: 32),
                    ] else ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No farm data available. Please check your connection.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFarmHeaderCard(MyFarmModel farm) {
    return StitchCard(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farm.farmName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${farm.landAcres} Acres • ${farm.soilType}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryGreenLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.water_drop, size: 14, color: AppColors.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      farm.waterSource,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreenDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF3F4F6)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Land', '${farm.landAcres} ac', Icons.landscape_outlined),
              _buildStatItem('Total Spent', '₹${farm.totalExpenses.toInt()}', Icons.currency_rupee),
              _buildStatItem('Activities', '${farm.recentActivities.length}', Icons.fact_check_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildAdvisoryCard(MyFarmModel farm) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.wb_sunny_outlined, color: AppColors.primaryGreenDark, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FARM & WEATHER ADVISORY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGreenDark,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  farm.weatherAdvisory,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF14532D),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCropCard(CropDetailModel crop) {
    return StitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.eco, color: Color(0xFFD97706), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crop.cropName + (crop.variety != null ? ' (${crop.variety})' : ''),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Sown on ${crop.sowingDate}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  'Day ${crop.daysSinceSowing}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Stage: ${_capitalize(crop.currentStage)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
              ),
              Text(
                '${crop.stageProgressPct}% Completed',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (crop.stageProgressPct / 100.0).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            ),
          ),
          if (crop.farmingGoal != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.track_changes, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Goal: ${crop.farmingGoal}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCropStageStepper(CropDetailModel crop) {
    return StitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'AGRONOMIC LIFECYCLE TIMELINE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                  letterSpacing: 0.7,
                ),
              ),
              Text(
                '6 Key Stages',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryGreen),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...crop.stages.asMap().entries.map((entry) {
            final idx = entry.key;
            final step = entry.value;
            final isLast = idx == crop.stages.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Indicator column
                  SizedBox(
                    width: 32,
                    child: Column(
                      children: [
                        _buildStageIndicator(step),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: step.isCompleted
                                  ? AppColors.primaryGreen
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Stage Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                step.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: step.isCurrent ? FontWeight.w800 : FontWeight.w600,
                                  color: step.isCurrent
                                      ? AppColors.primaryGreenDark
                                      : (step.isCompleted ? AppColors.textPrimary : AppColors.textSecondary),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: step.isCurrent
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  step.daysRange,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: step.isCurrent
                                        ? AppColors.primaryGreenDark
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (step.isCurrent)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Currently Active • Day ${crop.daysSinceSowing} in progress',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStageIndicator(CropStageStepModel step) {
    if (step.isCompleted) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.primaryGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 14, color: Colors.white),
      );
    } else if (step.isCurrent) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryGreen, width: 3),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
        ),
      );
    }
  }

  Widget _buildQuickActionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionBtn(
            icon: Icons.add_circle_outline,
            label: '+ Log Activity',
            color: const Color(0xFF2E7D32),
            onTap: () => _showLogActivityBottomSheet(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionBtn(
            icon: Icons.currency_rupee,
            label: '+ Add Expense',
            color: const Color(0xFFD97706),
            onTap: () => _showAddExpenseBottomSheet(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionBtn(
            icon: Icons.camera_alt_outlined,
            label: '📷 Crop Photo',
            color: const Color(0xFF2563EB),
            onTap: () => _showLogObservationBottomSheet(context),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesCard(MyFarmModel farm) {
    return StitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RECENT ACTIVITIES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                  letterSpacing: 0.7,
                ),
              ),
              Text(
                '${farm.recentActivities.length} Logged',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryGreen),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (farm.recentActivities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'No activities logged yet. Tap "+ Log Activity" above to add one.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            )
          else
            ...farm.recentActivities.map((act) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Icon(_getActivityIcon(act.activityType), size: 16, color: AppColors.primaryGreen),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _capitalize(act.activityType),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (act.description != null && act.description!.isNotEmpty)
                            Text(
                              act.description!,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (act.costIncurred > 0)
                      Text(
                        '₹${act.costIncurred.toInt()}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD97706),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryCard(MyFarmModel farm) {
    return StitchCard(
      backgroundColor: const Color(0xFFFFFBEB),
      borderColor: const Color(0xFFFDE68A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SEASON EXPENSES & INVESTMENTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB45309),
                  letterSpacing: 0.7,
                ),
              ),
              Text(
                'Total: ₹${farm.totalExpenses.toInt()}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB45309),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...farm.recentExpenses.map((exp) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _capitalize(exp.category),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF78350F),
                            ),
                          ),
                          if (exp.notes != null)
                            Text(
                              exp.notes!,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '₹${exp.amount.toInt()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'irrigation':
        return Icons.water_drop;
      case 'fertilizer':
        return Icons.scatter_plot;
      case 'pesticide':
        return Icons.pest_control;
      case 'weeding':
        return Icons.content_cut;
      case 'harvest':
        return Icons.agriculture;
      default:
        return Icons.check_circle_outline;
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  // Bottom Sheets for Interactive Logging
  void _showLogActivityBottomSheet(BuildContext context) {
    final typeController = TextEditingController(text: 'Irrigation');
    final descController = TextEditingController();
    final costController = TextEditingController(text: '0');
    final types = ['Irrigation', 'Fertilizer', 'Pesticide', 'Weeding', 'Scouting', 'Harvest'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Log Farm Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 14),
                  const Text('Activity Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: types.map((t) {
                      final selected = typeController.text == t;
                      return ChoiceChip(
                        label: Text(t),
                        selected: selected,
                        selectedColor: const Color(0xFFDCFCE7),
                        onSelected: (val) {
                          if (val) setModalState(() => typeController.text = t);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Description',
                      hintText: 'e.g. Applied Urea 45kg or 2 hours borewell',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: costController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cost Incurred (₹, optional)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  StitchButton(
                    text: 'Save Activity',
                    onPressed: () async {
                      final cost = double.tryParse(costController.text) ?? 0.0;
                      await ref.read(farmProvider.notifier).logActivity(
                            activityType: typeController.text.toLowerCase(),
                            description: descController.text.isNotEmpty ? descController.text : '${typeController.text} performed',
                            cost: cost,
                          );
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Activity "${typeController.text}" logged successfully!')),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddExpenseBottomSheet(BuildContext context) {
    final catController = TextEditingController(text: 'fertilizer');
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final categories = ['seeds', 'fertilizer', 'pesticide', 'labor', 'machinery', 'irrigation'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Record Farm Expense',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 14),
                  const Text('Expense Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: categories.map((cat) {
                      final selected = catController.text == cat;
                      return ChoiceChip(
                        label: Text(_capitalize(cat)),
                        selected: selected,
                        selectedColor: const Color(0xFFFEF3C7),
                        onSelected: (val) {
                          if (val) setModalState(() => catController.text = cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (₹)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Item details',
                      hintText: 'e.g. 1 bag DAP fertilizer',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  StitchButton(
                    text: 'Record Expense',
                    onPressed: () async {
                      final amount = double.tryParse(amountController.text) ?? 0.0;
                      if (amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid amount')),
                        );
                        return;
                      }
                      await ref.read(farmProvider.notifier).addExpense(
                            category: catController.text,
                            amount: amount,
                            notes: notesController.text.isNotEmpty ? notesController.text : null,
                          );
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Expense of ₹$amount recorded!')),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLogObservationBottomSheet(BuildContext context) {
    final noteController = TextEditingController();
    String healthStatus = 'healthy';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Crop Observation & Photo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 110,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB), style: BorderStyle.solid),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.camera_alt, size: 32, color: AppColors.textMuted),
                          SizedBox(height: 6),
                          Text('Simulate Camera Capture / Photo Upload', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Observed Crop Health', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('🌿 Healthy'),
                        selected: healthStatus == 'healthy',
                        selectedColor: const Color(0xFFDCFCE7),
                        onSelected: (val) => setModalState(() => healthStatus = 'healthy'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('🐛 Pest Sign'),
                        selected: healthStatus == 'pest_detected',
                        selectedColor: const Color(0xFFFEE2E2),
                        onSelected: (val) => setModalState(() => healthStatus = 'pest_detected'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('🍂 Yellowing'),
                        selected: healthStatus == 'yellowing',
                        selectedColor: const Color(0xFFFEF3C7),
                        onSelected: (val) => setModalState(() => healthStatus = 'yellowing'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Field Observation Note',
                      hintText: 'e.g. Good canopy formation, no leaf rust observed',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  StitchButton(
                    text: 'Save Observation',
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Crop observation saved to timeline!')),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
