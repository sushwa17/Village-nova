class ResidentProfileModel {
  final String id;
  final String fullName;
  final String? phoneNumber;
  final String? villageName;
  final String preferredLanguage;
  final List<String> roles;
  final bool verifiedBadge;

  const ResidentProfileModel({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    this.villageName,
    required this.preferredLanguage,
    required this.roles,
    this.verifiedBadge = false,
  });

  factory ResidentProfileModel.fromJson(Map<String, dynamic> json) {
    return ResidentProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String?,
      villageName: json['village_name'] as String?,
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['farmer'],
      verifiedBadge: json['verified_badge'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'village_name': villageName,
      'preferred_language': preferredLanguage,
      'roles': roles,
      'verified_badge': verifiedBadge,
    };
  }
}

class TodayActionModel {
  final String id;
  final String title;
  final String tag;
  final String actionType;
  bool completed;

  TodayActionModel({
    required this.id,
    required this.title,
    required this.tag,
    required this.actionType,
    this.completed = false,
  });

  factory TodayActionModel.fromJson(Map<String, dynamic> json) {
    return TodayActionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      tag: json['tag'] as String? ?? '🌾 Farm',
      actionType: json['action_type'] as String? ?? 'log_activity',
      completed: json['completed'] as bool? ?? false,
    );
  }
}

class HomeDashboardModel {
  final String greeting;
  final String residentName;
  final String locationLabel;
  final String weatherHeadline;
  final double rainfallMm;
  final String weatherAdvisory;
  final List<TodayActionModel> todayActions;
  final int completedTasks;
  final int totalTasks;
  final int progressPercentage;

  const HomeDashboardModel({
    required this.greeting,
    required this.residentName,
    required this.locationLabel,
    required this.weatherHeadline,
    required this.rainfallMm,
    required this.weatherAdvisory,
    required this.todayActions,
    required this.completedTasks,
    required this.totalTasks,
    required this.progressPercentage,
  });

  factory HomeDashboardModel.fromJson(Map<String, dynamic> json) {
    final weather = json['weather'] as Map<String, dynamic>? ?? {};
    final progress = json['progress'] as Map<String, dynamic>? ?? {};
    final actionsList = (json['today_actions'] as List<dynamic>?)
            ?.map((e) => TodayActionModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return HomeDashboardModel(
      greeting: json['greeting'] as String? ?? 'Good morning 👋',
      residentName: json['resident_name'] as String? ?? 'Resident',
      locationLabel: json['location_label'] as String? ?? 'Village',
      weatherHeadline: weather['headline'] as String? ?? 'Clear Weather',
      rainfallMm: (weather['rainfall_mm'] as num?)?.toDouble() ?? 0.0,
      weatherAdvisory: weather['advisory'] as String? ?? '',
      todayActions: actionsList,
      completedTasks: progress['completed'] as int? ?? 1,
      totalTasks: progress['total'] as int? ?? 3,
      progressPercentage: progress['percentage'] as int? ?? 33,
    );
  }
}
