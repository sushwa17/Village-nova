import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:villagenova/core/theme/app_colors.dart';
import 'package:villagenova/widgets/stitch_card.dart';
import 'package:villagenova/widgets/voice_mic_fab.dart';
import 'package:villagenova/providers/home_provider.dart';
import 'package:villagenova/models/resident_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenAskAI;
  final VoidCallback onOpenMySpace;
  final VoidCallback onOpenVillage;
  final VoidCallback onOpenSchemes;

  const HomeScreen({
    super.key,
    required this.onOpenAskAI,
    required this.onOpenMySpace,
    required this.onOpenVillage,
    required this.onOpenSchemes,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider.notifier).fetchHomeDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final dashboard = homeState.dashboard;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Greeting & Location
              _buildGreetingHeader(dashboard),
              const SizedBox(height: 20),

              // 2. Weather Advisory Card
              _buildWeatherCard(dashboard),
              const SizedBox(height: 16),

              // 3. Today's Actions Card (Central Action Hub)
              _buildTodayActionsCard(dashboard),
              const SizedBox(height: 16),

              // 4. Progress Dashboard Card (RE-SHAPE inspired)
              _buildProgressCard(dashboard),
              const SizedBox(height: 16),

              // 5. Quick Activity Buttons
              _buildQuickActionButtons(),
              const SizedBox(height: 16),

              // 6. Community & Schemes Row
              _buildCommunityAndSchemeCards(),
              const SizedBox(height: 80), // spacing for FAB
            ],
          ),
        ),
      ),

      // Persistent "Ask VillageNova" Voice Button
      floatingActionButton: VoiceMicFAB(
        onTap: widget.onOpenAskAI,
      ),

      // Standard Bottom Navigation Bar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (index) {
          setState(() => _navIndex = index);
          if (index == 1) widget.onOpenMySpace();
          if (index == 2) widget.onOpenVillage();
          if (index == 3) widget.onOpenSchemes();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primaryGreen),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.agriculture_outlined),
            selectedIcon: Icon(Icons.agriculture, color: AppColors.primaryGreen),
            label: 'My Space',
          ),
          NavigationDestination(
            icon: Icon(Icons.holiday_village_outlined),
            selectedIcon: Icon(Icons.holiday_village, color: AppColors.primaryGreen),
            label: 'Village',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance, color: AppColors.primaryGreen),
            label: 'Schemes',
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingHeader(HomeDashboardModel? dashboard) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dashboard?.greeting ?? 'Good morning, Ravi 👋',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.primaryGreen),
                const SizedBox(width: 4),
                Text(
                  dashboard?.locationLabel ?? 'Ananthagiri • Vikarabad',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        // AI Quick Launcher Badge
        GestureDetector(
          onTap: widget.onOpenAskAI,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryGreenLight),
            ),
            child: Row(
              children: const [
                Icon(Icons.auto_awesome, size: 16, color: AppColors.primaryGreen),
                SizedBox(width: 6),
                Text(
                  'Ask AI',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreenDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherCard(HomeDashboardModel? dashboard) {
    return StitchCard(
      backgroundColor: const Color(0xFFF0F7FF),
      borderColor: const Color(0xFFBAE6FD),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.cloudy_snowing, color: Color(0xFF0284C7), size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dashboard?.weatherHeadline ?? 'Rain Expected Today (6:00 PM)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0369A1),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dashboard?.weatherAdvisory ?? '14 mm forecast • Avoid irrigation this evening',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF075985),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayActionsCard(HomeDashboardModel? dashboard) {
    final actions = dashboard?.todayActions ?? [];

    return StitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "TODAY'S ACTIONS",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'Personalized for Soybean',
                style: TextStyle(fontSize: 12, color: AppColors.primaryGreen, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...actions.map((action) {
            final isDone = action.completed;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFFF9FAFB) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: Checkbox(
                  value: isDone,
                  activeColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  onChanged: (_) => ref.read(homeProvider.notifier).toggleAction(action.id),
                ),
                title: Text(
                  action.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    action.tag,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildProgressCard(HomeDashboardModel? dashboard) {
    final completedCount = dashboard?.completedTasks ?? 1;
    final totalCount = dashboard?.totalTasks ?? 3;
    final percentage = dashboard?.progressPercentage ?? 33;
    final progressVal = totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;

    return StitchCard(
      backgroundColor: const Color(0xFFFAF5FF),
      borderColor: const Color(0xFFE9D5FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'THIS WEEK PROGRESS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7E22CE),
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7E22CE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressVal,
              minHeight: 10,
              backgroundColor: const Color(0xFFF3E8FF),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9333EA)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completedCount of $totalCount planned activities logged this week',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B21A8), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.edit_calendar_outlined,
            label: '+ Log Activity',
            onTap: widget.onOpenMySpace,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.camera_alt_outlined,
            label: '📷 Crop Photo',
            onTap: widget.onOpenMySpace,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.currency_rupee,
            label: '💰 Add Expense',
            onTap: widget.onOpenMySpace,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
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
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryGreen),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityAndSchemeCards() {
    return Row(
      children: [
        Expanded(
          child: StitchCard(
            onTap: widget.onOpenVillage,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.campaign_outlined, color: AppColors.warning, size: 28),
                SizedBox(height: 8),
                Text('My Village', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('3 new panchayat updates', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StitchCard(
            onTap: widget.onOpenSchemes,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.stars_outlined, color: AppColors.primaryGreen, size: 28),
                SizedBox(height: 8),
                Text('Schemes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('2 schemes match your profile', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
