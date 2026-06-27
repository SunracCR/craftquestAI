class NotificationPayloadModel {
  const NotificationPayloadModel({
    this.quizId,
    this.quizTitle,
    this.classId,
    this.className,
    this.assignmentId,
    this.assignmentTitle,
    this.aiJobId,
    this.dueAtLabel,
    this.planName,
    this.daysRemaining,
    this.ownerName,
    this.route,
  });

  factory NotificationPayloadModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const NotificationPayloadModel();
    }
    return NotificationPayloadModel(
      quizId: json['quizId'] as String?,
      quizTitle: json['quizTitle'] as String?,
      classId: json['classId'] as String?,
      className: json['className'] as String?,
      assignmentId: json['assignmentId'] as String?,
      assignmentTitle: json['assignmentTitle'] as String?,
      aiJobId: json['aiJobId'] as String?,
      dueAtLabel: json['dueAtLabel'] as String?,
      planName: json['planName'] as String?,
      daysRemaining: json['daysRemaining'] as int?,
      ownerName: json['ownerName'] as String?,
      route: json['route'] as String?,
    );
  }

  final String? quizId;
  final String? quizTitle;
  final String? classId;
  final String? className;
  final String? assignmentId;
  final String? assignmentTitle;
  final String? aiJobId;
  final String? dueAtLabel;
  final String? planName;
  final int? daysRemaining;
  final String? ownerName;
  final String? route;
}

class NotificationModel {
  const NotificationModel({
    required this.notificationId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.data,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
      data: NotificationPayloadModel.fromJson(
        json['data'] as Map<String, dynamic>?,
      ),
    );
  }

  final String notificationId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final NotificationPayloadModel? data;
}

class NotificationListResultModel {
  const NotificationListResultModel({
    required this.items,
    required this.unreadCount,
    this.nextCursor,
  });

  factory NotificationListResultModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return NotificationListResultModel(
      items: rawItems
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  final List<NotificationModel> items;
  final String? nextCursor;
  final int unreadCount;
}

class NotificationPreferenceModel {
  const NotificationPreferenceModel({
    required this.type,
    required this.inAppEnabled,
    required this.pushEnabled,
    required this.emailEnabled,
  });

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferenceModel(
      type: json['type'] as String,
      inAppEnabled: json['inAppEnabled'] as bool? ?? true,
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'inAppEnabled': inAppEnabled,
        'pushEnabled': pushEnabled,
        'emailEnabled': emailEnabled,
      };

  NotificationPreferenceModel copyWith({
    bool? inAppEnabled,
    bool? pushEnabled,
    bool? emailEnabled,
  }) {
    return NotificationPreferenceModel(
      type: type,
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
    );
  }

  final String type;
  final bool inAppEnabled;
  final bool pushEnabled;
  final bool emailEnabled;
}

class NotificationPreferencesModel {
  const NotificationPreferencesModel({required this.preferences});

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    final raw = json['preferences'] as List<dynamic>? ?? const [];
    return NotificationPreferencesModel(
      preferences: raw
          .map(
            (e) => NotificationPreferenceModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  final List<NotificationPreferenceModel> preferences;
}
