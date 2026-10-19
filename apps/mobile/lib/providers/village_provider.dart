import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:villagenova/models/village_feed_model.dart';
import 'package:villagenova/core/network/api_client.dart';
import 'package:villagenova/providers/auth_provider.dart';

enum VillageStatus { initial, loading, loaded, error }

class VillageState {
  final VillageStatus status;
  final VillageFeedModel? feed;
  final String selectedCategory; // 'all', 'panchayat', 'agriculture', 'health', 'emergency'
  final bool isPostingNotice;
  final String? errorMessage;

  const VillageState({
    this.status = VillageStatus.initial,
    this.feed,
    this.selectedCategory = 'all',
    this.isPostingNotice = false,
    this.errorMessage,
  });

  VillageState copyWith({
    VillageStatus? status,
    VillageFeedModel? feed,
    String? selectedCategory,
    bool? isPostingNotice,
    String? errorMessage,
  }) {
    return VillageState(
      status: status ?? this.status,
      feed: feed ?? this.feed,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isPostingNotice: isPostingNotice ?? this.isPostingNotice,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  List<VillageUpdateModel> get filteredBulletins {
    if (feed == null) return [];
    if (selectedCategory == 'all') return feed!.bulletins;
    if (selectedCategory == 'emergency') {
      return feed!.bulletins.where((b) => b.isEmergency).toList();
    }
    return feed!.bulletins
        .where((b) => b.category.toLowerCase() == selectedCategory.toLowerCase())
        .toList();
  }
}

class VillageNotifier extends StateNotifier<VillageState> {
  final ApiClient apiClient;

  VillageNotifier(this.apiClient) : super(const VillageState()) {
    fetchVillageFeed();
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  Future<void> fetchVillageFeed({String villageId = '3fa85f64-5717-4562-b3fc-2c963f66afa6'}) async {
    state = state.copyWith(status: VillageStatus.loading);
    try {
      final response = await apiClient.dio.get('/villages/$villageId/feed');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final model = VillageFeedModel.fromJson(response.data['data'] as Map<String, dynamic>);
        state = state.copyWith(status: VillageStatus.loaded, feed: model);
        return;
      }
    } catch (_) {
      // Offline fallback
    }
    _setFallbackFeed();
  }

  Future<bool> postBulletin({
    required String title,
    required String content,
    required String category,
    bool isEmergency = false,
    String villageId = '3fa85f64-5717-4562-b3fc-2c963f66afa6',
  }) async {
    state = state.copyWith(isPostingNotice: true);
    try {
      await apiClient.dio.post(
        '/villages/$villageId/bulletins',
        data: {
          'title': title,
          'content': content,
          'category': category,
          'is_emergency': isEmergency,
          'author_name': 'Ravi (Resident Contributor)',
          'author_role': 'Farmer / Resident',
        },
      );
    } catch (_) {}

    // Optimistically prepend locally
    if (state.feed != null) {
      final newBulletin = VillageUpdateModel(
        id: 'bul_${DateTime.now().millisecondsSinceEpoch}',
        villageId: villageId,
        title: title,
        content: content,
        category: category,
        isEmergency: isEmergency,
        isVerified: true,
        authorName: 'Ravi (Resident Contributor)',
        authorRole: 'Verified Citizen',
        createdAt: DateTime.now().toIso8601String(),
      );

      final updatedBulletins = [newBulletin, ...state.feed!.bulletins];
      final alertsCount = updatedBulletins.where((b) => b.isEmergency).length;

      final updatedFeed = VillageFeedModel(
        villageId: state.feed!.villageId,
        villageName: state.feed!.villageName,
        mandal: state.feed!.mandal,
        district: state.feed!.district,
        activeAlertsCount: alertsCount,
        weather: state.feed!.weather,
        mandiPrices: state.feed!.mandiPrices,
        bulletins: updatedBulletins,
      );

      state = state.copyWith(feed: updatedFeed, isPostingNotice: false);
      return true;
    }

    state = state.copyWith(isPostingNotice: false);
    return true;
  }

  void _setFallbackFeed() {
    final weather = VillageWeatherModel(
      villageName: 'Ananthagiri',
      tempC: 29.4,
      condition: 'Scattered Rain & Thunderstorms',
      humidityPct: 82,
      windSpeedKmh: 14.5,
      rainProbPct: 85,
      rainfallMm: 14.0,
      expectedRainTime: '6:00 PM today',
      advisory: 'Heavy rain (14mm) expected around 6:00 PM. Conclude pesticide spray and field hoeing by 4:30 PM. Keep drainage channels unobstructed.',
      hourly: const [
        WeatherHourModel(time: '2:00 PM', tempC: 31.0, rainProb: 20, condition: 'Partly Cloudy', icon: 'partly_cloudy'),
        WeatherHourModel(time: '4:00 PM', tempC: 29.5, rainProb: 45, condition: 'Overcast Clouds', icon: 'cloudy'),
        WeatherHourModel(time: '6:00 PM', tempC: 26.0, rainProb: 90, condition: 'Thunderstorm', icon: 'thunderstorm'),
        WeatherHourModel(time: '8:00 PM', tempC: 24.5, rainProb: 70, condition: 'Showers', icon: 'rain'),
        WeatherHourModel(time: '10:00 PM', tempC: 24.0, rainProb: 30, condition: 'Cloudy', icon: 'cloudy'),
      ],
    );

    final mandi = const [
      MandiPriceModel(
        commodity: 'Soybean (JS-335 / Yellow)',
        market: 'Vikarabad APMC',
        modalPrice: 4850.0,
        minPrice: 4620.0,
        maxPrice: 4980.0,
        unit: 'Quintal',
        priceChange: 70.0,
        trend: 'up',
        reportedDate: 'Today',
      ),
      MandiPriceModel(
        commodity: 'Cotton (Medium Staple)',
        market: 'Tandur APMC',
        modalPrice: 7200.0,
        minPrice: 6900.0,
        maxPrice: 7450.0,
        unit: 'Quintal',
        priceChange: 120.0,
        trend: 'up',
        reportedDate: 'Today',
      ),
      MandiPriceModel(
        commodity: 'Red Gram / Tur (Desi)',
        market: 'Vikarabad APMC',
        modalPrice: 6900.0,
        minPrice: 6650.0,
        maxPrice: 7150.0,
        unit: 'Quintal',
        priceChange: -40.0,
        trend: 'down',
        reportedDate: 'Today',
      ),
      MandiPriceModel(
        commodity: 'Maize (Hybrid Yellow)',
        market: 'Sadasivpet APMC',
        modalPrice: 2150.0,
        minPrice: 2050.0,
        maxPrice: 2220.0,
        unit: 'Quintal',
        priceChange: 0.0,
        trend: 'stable',
        reportedDate: 'Today',
      ),
    ];

    final bulletins = [
      VillageUpdateModel(
        id: 'bul_001',
        villageId: '3fa85f64-5717-4562-b3fc-2c963f66afa6',
        title: '⚡ 3-Phase Agricultural Power Schedule Changed',
        content: 'Due to grid maintenance, 3-phase power for borewells will run from 4:00 AM to 11:00 AM and 7:00 PM to 10:00 PM starting Tuesday.',
        category: 'panchayat',
        isEmergency: true,
        isVerified: true,
        authorName: 'TSSPDCL Vikarabad & Gram Panchayat',
        authorRole: 'Assistant Engineer / Panchayat Admin',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      ),
      VillageUpdateModel(
        id: 'bul_002',
        villageId: '3fa85f64-5717-4562-b3fc-2c963f66afa6',
        title: '🌾 Subsidized Gypsum & Bio-fertilizer Distribution',
        content: 'Rythu Bharosa Kendra (RBK) Ananthagiri has received 200 bags of agricultural gypsum and Trichoderma. Bring Pattadar Passbook before Friday 5 PM.',
        category: 'agriculture',
        isEmergency: false,
        isVerified: true,
        authorName: 'Agriculture Extension Officer (AEO)',
        authorRole: 'Department of Agriculture',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
      ),
      VillageUpdateModel(
        id: 'bul_003',
        villageId: '3fa85f64-5717-4562-b3fc-2c963f66afa6',
        title: '🏥 Free Monsoon Health & Eye Checkup Camp',
        content: 'Primary Health Centre (PHC) Ananthagiri is organizing a free health screening camp at Zilla Parishad High School ground this Saturday 9 AM.',
        category: 'health',
        isEmergency: false,
        isVerified: true,
        authorName: 'Dr. Sunitha Reddy',
        authorRole: 'Medical Officer, PHC Ananthagiri',
        createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      ),
    ];

    final fallback = VillageFeedModel(
      villageId: '3fa85f64-5717-4562-b3fc-2c963f66afa6',
      villageName: 'Ananthagiri',
      mandal: 'Vikarabad',
      district: 'Vikarabad',
      activeAlertsCount: 1,
      weather: weather,
      mandiPrices: mandi,
      bulletins: bulletins,
    );

    state = state.copyWith(status: VillageStatus.loaded, feed: fallback);
  }
}

final villageProvider = StateNotifierProvider<VillageNotifier, VillageState>((ref) {
  final client = ref.watch(apiClientProvider);
  return VillageNotifier(client);
});
