class ShareCodeModel {
  const ShareCodeModel({
    required this.shareCodeId,
    required this.code,
    required this.codeType,
    required this.maxRedemptions,
    required this.redemptionsCount,
    required this.status,
    required this.accessPolicy,
    this.classId,
    this.isExisting = false,
    this.joinUrl,
  });

  factory ShareCodeModel.fromJson(Map<String, dynamic> json) {
    return ShareCodeModel(
      shareCodeId: json['shareCodeId'] as String,
      code: json['code'] as String,
      codeType: json['codeType'] as String,
      maxRedemptions: json['maxRedemptions'] as int,
      redemptionsCount: json['redemptionsCount'] as int? ?? 0,
      status: json['status'] as String,
      accessPolicy: json['accessPolicy'] as String? ?? 'registered_open',
      classId: json['classId'] as String?,
      isExisting: json['isExisting'] as bool? ?? false,
      joinUrl: json['joinUrl'] as String?,
    );
  }

  final String shareCodeId;
  final String code;
  final String codeType;
  final int maxRedemptions;
  final int redemptionsCount;
  final String status;
  final String accessPolicy;
  final String? classId;
  final bool isExisting;
  final String? joinUrl;
}

class RedeemResultModel {
  const RedeemResultModel({
    required this.quizId,
    required this.quizTitle,
    this.alreadyInSharedList = false,
  });

  factory RedeemResultModel.fromJson(Map<String, dynamic> json) {
    return RedeemResultModel(
      quizId: json['quizId'] as String,
      quizTitle: json['quizTitle'] as String,
      alreadyInSharedList: json['alreadyInSharedList'] as bool? ?? false,
    );
  }

  final String quizId;
  final String quizTitle;
  final bool alreadyInSharedList;
}

class AccessibleQuizModel {
  const AccessibleQuizModel({
    required this.quizId,
    required this.title,
    required this.questionCount,
    required this.accessType,
    required this.sharedByUserId,
    this.sharedByDisplayName,
  });

  factory AccessibleQuizModel.fromJson(Map<String, dynamic> json) {
    return AccessibleQuizModel(
      quizId: json['quizId'] as String,
      title: json['title'] as String,
      questionCount: json['questionCount'] as int? ?? 0,
      accessType: json['accessType'] as String? ?? 'redeemed',
      sharedByUserId: json['sharedByUserId'] as String,
      sharedByDisplayName: json['sharedByDisplayName'] as String?,
    );
  }

  final String quizId;
  final String title;
  final int questionCount;
  final String accessType;
  final String sharedByUserId;
  final String? sharedByDisplayName;
}

class InviteUsersResultModel {
  const InviteUsersResultModel({required this.results});

  factory InviteUsersResultModel.fromJson(Map<String, dynamic> json) {
    final items = json['results'] as List<dynamic>? ?? [];
    return InviteUsersResultModel(
      results: items
          .map(
            (e) => InviteUserResultItemModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  final List<InviteUserResultItemModel> results;
}

class InviteUserResultItemModel {
  const InviteUserResultItemModel({
    required this.email,
    required this.outcome,
    this.displayName,
  });

  factory InviteUserResultItemModel.fromJson(Map<String, dynamic> json) {
    return InviteUserResultItemModel(
      email: json['email'] as String,
      outcome: json['outcome'] as String,
      displayName: json['displayName'] as String?,
    );
  }

  final String email;
  final String outcome;
  final String? displayName;
}
