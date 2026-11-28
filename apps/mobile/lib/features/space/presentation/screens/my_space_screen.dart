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

                      // 5. Latest Leaf Crop Doctor Diagnosis Card (Week 12)
                      if (farmState.latestDiagnosis != null) ...[
                        _buildLeafDoctorCard(farmState.latestDiagnosis!),
                        const SizedBox(height: 16),
                      ],

                      // 6. Quick Farm Action Buttons
                      _buildQuickActionRow(context),
                      const SizedBox(height: 16),

                      // 7. Recent Activities Log
                      _buildRecentActivitiesCard(farm),
                      const SizedBox(height: 16),

                      // 8. Expenses & Financial Breakdown
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
                        '${crop.cropName}${crop.variety != null ? ' (${crop.variety})' : ''}',
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
                Expanded(
                  child: Text(
                    'Goal: ${crop.farmingGoal}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
          }),
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

  Widget _buildLeafDoctorCard(LeafDoctorDiagnosisModel diag) {
    final isDanger = diag.severityLevel == 'high' || diag.severityLevel == 'critical';
    final bg = diag.isHealthy
        ? const Color(0xFFF0FDF4)
        : (isDanger ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB));
    final border = diag.isHealthy
        ? const Color(0xFFBBF7D0)
        : (isDanger ? const Color(0xFFFECACA) : const Color(0xFFFDE68A));
    final badgeColor = diag.isHealthy
        ? const Color(0xFF15803D)
        : (isDanger ? const Color(0xFFB91C1C) : const Color(0xFFB45309));

    return StitchCard(
      backgroundColor: bg,
      borderColor: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LEAF CROP DOCTOR • ${(diag.confidenceScore * 100).round()}% CONFIDENCE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                  letterSpacing: 0.6,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  diag.severityLevel.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            diag.diseaseOrPestName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            diag.summary,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
          ),
          if (diag.weatherSprayWarning != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Text(
                diag.weatherSprayWarning!,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
              ),
            ),
          ],
          if (diag.organicRemedies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Organic IPM: ${diag.organicRemedies.first.title} (${diag.organicRemedies.first.dosage})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryGreenDark),
            ),
          ],
          if (diag.chemicalRemedies.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Recommended Dose: ${diag.chemicalRemedies.first.title} (${diag.chemicalRemedies.first.dosage})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ],
      ),
    );
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
            label: 'Leaf Doctor',
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
            }),
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
          }),
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
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  // Bottom Sheets for Interactive Logging
  void _showLogActivityBottomSheet(BuildContext context) {
    final typeController = TextEditingController(text: 'Irrigation');
    final descController = TextEditingController();
    final costController = TextEditingController(text: '0');
    const types = ['Irrigation', 'Fertilizer', 'Pesticide', 'Weeding', 'Scouting', 'Harvest'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
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
                      final navigator = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      final cost = double.tryParse(costController.text) ?? 0.0;
                      await ref.read(farmProvider.notifier).logActivity(
                            activityType: typeController.text.toLowerCase(),
                            description: descController.text.isNotEmpty ? descController.text : '${typeController.text} performed',
                            cost: cost,
                          );
                      if (ctx.mounted) {
                        navigator.pop();
                      }
                      if (mounted) {
                        messenger.showSnackBar(
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
    const categories = ['seeds', 'fertilizer', 'pesticide', 'labor', 'machinery', 'irrigation'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
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
                      final navigator = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      final amount = double.tryParse(amountController.text) ?? 0.0;
                      if (amount <= 0) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Please enter a valid amount')),
                        );
                        return;
                      }
                      await ref.read(farmProvider.notifier).addExpense(
                            category: catController.text,
                            amount: amount,
                            notes: notesController.text.isNotEmpty ? notesController.text : null,
                          );
                      if (ctx.mounted) {
                        navigator.pop();
                      }
                      if (mounted) {
                        messenger.showSnackBar(
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
    final noteController = TextEditingController(
      text: 'Yellow mosaic mottling on lower leaves with small whiteflies.',
    );
    String healthStatus = 'yellowing';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Leaf Crop Doctor',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 96,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 28, color: AppColors.textMuted),
                          SizedBox(height: 4),
                          Text(
                            'Camera Leaf Scan Ready (Soybean JS-335)',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Observed Symptom Preset', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Healthy'),
                        selected: healthStatus == 'healthy',
                        selectedColor: const Color(0xFFDCFCE7),
                        onSelected: (val) => setModalState(() {
                          healthStatus = 'healthy';
                          noteController.text = 'Healthy dark green leaf canopy with no spots.';
                        }),
                      ),
                      ChoiceChip(
                        label: const Text('Yellowing / Whitefly'),
                        selected: healthStatus == 'yellowing',
                        selectedColor: const Color(0xFFFEF3C7),
                        onSelected: (val) => setModalState(() {
                          healthStatus = 'yellowing';
                          noteController.text = 'Yellow mosaic mottling on lower leaves with small whiteflies.';
                        }),
                      ),
                      ChoiceChip(
                        label: const Text('Caterpillar Holes'),
                        selected: healthStatus == 'pest_detected',
                        selectedColor: const Color(0xFFFEE2E2),
                        onSelected: (val) => setModalState(() {
                          healthStatus = 'pest_detected';
                          noteController.text = 'Chewed leaf margins and caterpillar feeding holes on upper leaves.';
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Observed Leaf / Pod Symptoms',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  StitchButton(
                    text: 'Diagnose with Leaf Doctor',
                    onPressed: () async {
                      final navigator = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      final diag = await ref.read(farmProvider.notifier).diagnoseLeaf(
                            symptomText: noteController.text.isNotEmpty
                                ? noteController.text
                                : 'Routine canopy inspection',
                            severityHint: healthStatus,
                          );
                      if (ctx.mounted) {
                        navigator.pop();
                      }
                      if (mounted && diag != null) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Leaf Doctor: ${diag.diseaseOrPestName} (${diag.severityLevel.toUpperCase()})',
                            ),
                          ),
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
}
