import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:villagenova/core/theme/app_colors.dart';
import 'package:villagenova/widgets/stitch_card.dart';
import 'package:villagenova/widgets/stitch_button.dart';
import 'package:villagenova/providers/village_provider.dart';
import 'package:villagenova/models/village_feed_model.dart';

class MyVillageScreen extends ConsumerStatefulWidget {
  const MyVillageScreen({super.key});

  @override
  ConsumerState<MyVillageScreen> createState() => _MyVillageScreenState();
}

class _MyVillageScreenState extends ConsumerState<MyVillageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(villageProvider.notifier).fetchVillageFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final villageState = ref.watch(villageProvider);
    final feed = villageState.feed;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'My Village • గ్రామ వేదిక',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sync Village Feed',
            onPressed: () => ref.read(villageProvider.notifier).fetchVillageFeed(),
          ),
        ],
      ),
      body: villageState.status == VillageStatus.loading && feed == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: () => ref.read(villageProvider.notifier).fetchVillageFeed(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (feed != null) ...[
                      // 1. Village Header
                      _buildVillageHeader(feed),
                      const SizedBox(height: 14),

                      // 2. Urgent Emergency Banner (if any)
                      if (feed.activeAlertsCount > 0) ...[
                        _buildUrgentAlertBanner(feed),
                        const SizedBox(height: 14),
                      ],

                      // 3. Hyperlocal Weather & Ag Advisory Card
                      _buildWeatherCard(feed.weather),
                      const SizedBox(height: 16),

                      // 4. APMC Mandi Market Prices Ticker
                      _buildMandiPricesSection(feed.mandiPrices),
                      const SizedBox(height: 16),

                      // 5. Category Filter Bar
                      _buildCategoryFilters(villageState.selectedCategory),
                      const SizedBox(height: 14),

                      // 6. Community Bulletin Board Feed
                      _buildBulletinsList(villageState.filteredBulletins),
                      const SizedBox(height: 32),
                    ] else ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'Unable to load village feed. Pull down to refresh.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.campaign_outlined),
        label: const Text('Post Notice', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => _showPostNoticeModal(context),
      ),
    );
  }

  Widget _buildVillageHeader(VillageFeedModel feed) {
    return StitchCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.holiday_village, color: AppColors.primaryGreen, size: 28),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feed.villageName,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${feed.mandal} Mandal • ${feed.district}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, size: 14, color: AppColors.primaryGreen),
                const SizedBox(width: 4),
                Text(
                  '${feed.bulletins.length} Notices',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentAlertBanner(VillageFeedModel feed) {
    final emergency = feed.bulletins.firstWhere(
      (b) => b.isEmergency,
      orElse: () => feed.bulletins.first,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🚨', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'URGENT PANCHAYAT BROADCAST',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF991B1B),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  emergency.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF7F1D1D)),
                ),
                const SizedBox(height: 2),
                Text(
                  emergency.content,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(VillageWeatherModel weather) {
    return StitchCard(
      backgroundColor: const Color(0xFFF0F9FF),
      borderColor: const Color(0xFFBAE6FD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloudy_snowing, color: Color(0xFF0284C7), size: 28),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather.tempC}°C',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                      Text(
                        weather.condition,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${weather.rainProbPct}% Rain',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0369A1)),
                    ),
                    Text(
                      '${weather.rainfallMm} mm',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0F2FE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.wb_incandescent_outlined, size: 16, color: Color(0xFF0284C7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    weather.advisory,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF075985), fontWeight: FontWeight.w500, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Hourly Forecast Chips
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: weather.hourly.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final h = weather.hourly[idx];
                return Container(
                  width: 72,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0F2FE)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(h.time, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text('${h.tempC.toInt()}°', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      Text('${h.rainProb}% 💧', style: const TextStyle(fontSize: 9, color: Color(0xFF0284C7), fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMandiPricesSection(List<MandiPriceModel> prices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'APMC MANDI RATES (వికారాబాద్ మార్కెట్)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
                letterSpacing: 0.7,
              ),
            ),
            Text(
              'Live Agmarknet',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryGreen),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 98,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: prices.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, idx) {
              final p = prices[idx];
              final isUp = p.trend == 'up';
              final isDown = p.trend == 'down';

              return Container(
                width: 175,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            p.commodity,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          isUp ? Icons.trending_up : (isDown ? Icons.trending_down : Icons.trending_flat),
                          size: 16,
                          color: isUp ? AppColors.success : (isDown ? AppColors.error : AppColors.textMuted),
                        ),
                      ],
                    ),
                    Text(
                      p.market,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${p.modalPrice.toInt()} / ${p.unit}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        if (p.priceChange != 0)
                          Text(
                            '${isUp ? '+' : ''}₹${p.priceChange.toInt()}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isUp ? AppColors.success : AppColors.error,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters(String selected) {
    final categories = [
      {'key': 'all', 'label': 'All Notices'},
      {'key': 'panchayat', 'label': '🏛️ Panchayat'},
      {'key': 'agriculture', 'label': '🌾 Agriculture'},
      {'key': 'health', 'label': '🏥 Health'},
      {'key': 'emergency', 'label': '🚨 Emergency'},
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final cat = categories[idx];
          final isSelected = selected == cat['key'];

          return ChoiceChip(
            label: Text(
              cat['label']!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primaryGreenDark : AppColors.textSecondary,
              ),
            ),
            selected: isSelected,
            selectedColor: const Color(0xFFDCFCE7),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: BorderSide(
              color: isSelected ? AppColors.primaryGreenLight : const Color(0xFFE5E7EB),
            ),
            onSelected: (_) => ref.read(villageProvider.notifier).setCategory(cat['key']!),
          );
        },
      ),
    );
  }

  Widget _buildBulletinsList(List<VillageUpdateModel> bulletins) {
    if (bulletins.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Text(
            'No notices in this category.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: bulletins.map((b) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: StitchCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(b.category).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        b.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _getCategoryColor(b.category),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Row(
                      children: const [
                        Icon(Icons.verified, size: 14, color: AppColors.primaryGreen),
                        SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryGreen),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  b.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  b.content,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.authorName,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        Text(
                          b.authorRole,
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    Text(
                      'Recently',
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'panchayat':
        return const Color(0xFF1E40AF);
      case 'agriculture':
        return AppColors.primaryGreen;
      case 'health':
        return const Color(0xFF059669);
      case 'emergency':
        return AppColors.emergencyAlert;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showPostNoticeModal(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String category = 'community';
    bool isEmergency = false;

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
                    'Post Village Notice / Announcement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['panchayat', 'agriculture', 'health', 'community'].map((c) {
                      final selected = category == c;
                      return ChoiceChip(
                        label: Text(c[0].toUpperCase() + c.substring(1)),
                        selected: selected,
                        selectedColor: const Color(0xFFDCFCE7),
                        onSelected: (val) {
                          if (val) setModalState(() => category = c);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Notice Title',
                      hintText: 'e.g. Free Cattle Vaccination Camp',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Announcement Details',
                      hintText: 'Date, timing, location, and requirements...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mark as Urgent Broadcast', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    value: isEmergency,
                    activeColor: AppColors.emergencyAlert,
                    onChanged: (val) => setModalState(() => isEmergency = val ?? false),
                  ),
                  const SizedBox(height: 14),
                  StitchButton(
                    text: 'Publish Notice to Village',
                    onPressed: () async {
                      if (titleController.text.isEmpty || contentController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter both title and details')),
                        );
                        return;
                      }

                      await ref.read(villageProvider.notifier).postBulletin(
                            title: titleController.text,
                            content: contentController.text,
                            category: category,
                            isEmergency: isEmergency,
                          );

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Village notice published successfully!')),
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
