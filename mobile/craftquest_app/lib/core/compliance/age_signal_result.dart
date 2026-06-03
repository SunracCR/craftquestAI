/// Resultado de [AgeSignalService.checkAgeSignals] desde Play Age Signals (Android).
class AgeSignalResult {
  const AgeSignalResult({
    this.userStatus,
    this.ageLower,
    this.ageUpper,
    this.installId,
    this.mostRecentApprovalDate,
    required this.requiresParentalConsent,
    this.errorCode,
    this.errorMessage,
  });

  factory AgeSignalResult.fromMap(Map<dynamic, dynamic> map) {
    return AgeSignalResult(
      userStatus: map['userStatus'] as String?,
      ageLower: _asInt(map['ageLower']),
      ageUpper: _asInt(map['ageUpper']),
      installId: map['installId'] as String?,
      mostRecentApprovalDate: map['mostRecentApprovalDate'] as String?,
      requiresParentalConsent: map['requiresParentalConsent'] == true,
      errorCode: _asInt(map['errorCode']),
      errorMessage: map['errorMessage'] as String?,
    );
  }

  final String? userStatus;
  final int? ageLower;
  final int? ageUpper;
  final String? installId;
  final String? mostRecentApprovalDate;
  final bool requiresParentalConsent;
  final int? errorCode;
  final String? errorMessage;

  bool get hasError => errorCode != null;

  static int? _asInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }
}
