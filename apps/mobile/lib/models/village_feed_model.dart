class WeatherHourModel {
  final String time;
  final double tempC;
  final int rainProb;
  final String condition;
  final String icon;

  const WeatherHourModel({
    required this.time,
    required this.tempC,
    required this.rainProb,
    required this.condition,
    required this.icon,
  });

  factory WeatherHourModel.fromJson(Map<String, dynamic> json) {
    return WeatherHourModel(
      time: json['time'] as String? ?? '',
      tempC: (json['temp_c'] as num?)?.toDouble() ?? 28.0,
      rainProb: json['rain_prob'] as int? ?? 0,
      condition: json['condition'] as String? ?? 'Cloudy',
      icon: json['icon'] as String? ?? 'cloudy',
    );
  }
}

class VillageWeatherModel {
  final String villageName;
  final double tempC;
  final String condition;
  final int humidityPct;
  final double windSpeedKmh;
  final int rainProbPct;
  final double rainfallMm;
  final String? expectedRainTime;
  final String advisory;
  final List<WeatherHourModel> hourly;

  const VillageWeatherModel({
    required this.villageName,
    required this.tempC,
    required this.condition,
    required this.humidityPct,
    required this.windSpeedKmh,
    required this.rainProbPct,
    required this.rainfallMm,
    this.expectedRainTime,
    required this.advisory,
    required this.hourly,
  });

  factory VillageWeatherModel.fromJson(Map<String, dynamic> json) {
    return VillageWeatherModel(
      villageName: json['village_name'] as String? ?? 'Village',
      tempC: (json['temp_c'] as num?)?.toDouble() ?? 29.0,
      condition: json['condition'] as String? ?? 'Scattered Clouds',
      humidityPct: json['humidity_pct'] as int? ?? 80,
      windSpeedKmh: (json['wind_speed_kmh'] as num?)?.toDouble() ?? 12.0,
      rainProbPct: json['rain_prob_pct'] as int? ?? 50,
      rainfallMm: (json['rainfall_mm'] as num?)?.toDouble() ?? 0.0,
      expectedRainTime: json['expected_rain_time'] as String?,
      advisory: json['advisory'] as String? ?? 'Monitor local conditions.',
      hourly: (json['hourly'] as List<dynamic>?)
              ?.map((e) => WeatherHourModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MandiPriceModel {
  final String commodity;
  final String market;
  final double modalPrice;
  final double minPrice;
  final double maxPrice;
  final String unit;
  final double priceChange;
  final String trend; // 'up', 'down', 'stable'
  final String reportedDate;

  const MandiPriceModel({
    required this.commodity,
    required this.market,
    required this.modalPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.unit,
    required this.priceChange,
    required this.trend,
    required this.reportedDate,
  });

  factory MandiPriceModel.fromJson(Map<String, dynamic> json) {
    return MandiPriceModel(
      commodity: json['commodity'] as String? ?? '',
      market: json['market'] as String? ?? '',
      modalPrice: (json['modal_price'] as num?)?.toDouble() ?? 0.0,
      minPrice: (json['min_price'] as num?)?.toDouble() ?? 0.0,
      maxPrice: (json['max_price'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'Quintal',
      priceChange: (json['price_change'] as num?)?.toDouble() ?? 0.0,
      trend: json['trend'] as String? ?? 'stable',
      reportedDate: json['reported_date'] as String? ?? '',
    );
  }
}

class VillageUpdateModel {
  final String id;
  final String villageId;
  final String title;
  final String content;
  final String category;
  final bool isEmergency;
  final bool isVerified;
  final String authorName;
  final String authorRole;
  final String createdAt;

  const VillageUpdateModel({
    required this.id,
    required this.villageId,
    required this.title,
    required this.content,
    required this.category,
    required this.isEmergency,
    required this.isVerified,
    required this.authorName,
    required this.authorRole,
    required this.createdAt,
  });

  factory VillageUpdateModel.fromJson(Map<String, dynamic> json) {
    return VillageUpdateModel(
      id: json['id'] as String? ?? '',
      villageId: json['village_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      isEmergency: json['is_emergency'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? true,
      authorName: json['author_name'] as String? ?? 'Panchayat Secretary',
      authorRole: json['author_role'] as String? ?? 'Gram Panchayat',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class VillageFeedModel {
  final String villageId;
  final String villageName;
  final String mandal;
  final String district;
  final int activeAlertsCount;
  final VillageWeatherModel weather;
  final List<MandiPriceModel> mandiPrices;
  final List<VillageUpdateModel> bulletins;

  const VillageFeedModel({
    required this.villageId,
    required this.villageName,
    required this.mandal,
    required this.district,
    required this.activeAlertsCount,
    required this.weather,
    required this.mandiPrices,
    required this.bulletins,
  });

  factory VillageFeedModel.fromJson(Map<String, dynamic> json) {
    return VillageFeedModel(
      villageId: json['village_id'] as String? ?? '',
      villageName: json['village_name'] as String? ?? 'Ananthagiri',
      mandal: json['mandal'] as String? ?? 'Vikarabad',
      district: json['district'] as String? ?? 'Vikarabad',
      activeAlertsCount: json['active_alerts_count'] as int? ?? 0,
      weather: VillageWeatherModel.fromJson(json['weather'] as Map<String, dynamic>? ?? {}),
      mandiPrices: (json['mandi_prices'] as List<dynamic>?)
              ?.map((e) => MandiPriceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      bulletins: (json['bulletins'] as List<dynamic>?)
              ?.map((e) => VillageUpdateModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
