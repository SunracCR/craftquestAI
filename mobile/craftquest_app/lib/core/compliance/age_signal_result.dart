/// Resultado de [AgeSignalService.checkAgeSignals] desde Play Age Signals (Android).
///
/// A partir de la versión 0.0.4 del SDK, `userStatus` fue deprecado y
/// reemplazado por [ageRangeSource] (fuente/tier de la señal de edad) y
/// [significantChangeStatus] (estado de aprobación de cambios significativos).
class AgeSignalResult {
  const AgeSignalResult({
    this.ageSignalsStatus,
    this.ageRangeSource,
    this.ageLower,
    this.ageUpper,
    this.installId,
    this.significantChangeStatus,
    this.significantChangeApprovalDate,
    required this.requiresParentalConsent,
    this.errorCode,
    this.errorMessage,
  });

  factory AgeSignalResult.fromMap(Map<dynamic, dynamic> map) {
    return AgeSignalResult(
      ageSignalsStatus: map['ageSignalsStatus'] as String?,
      ageRangeSource: map['ageRangeSource'] as String?,
      ageLower: _asInt(map['ageLower']),
      ageUpper: _asInt(map['ageUpper']),
      installId: map['installId'] as String?,
      significantChangeStatus: map['significantChangeStatus'] as String?,
      significantChangeApprovalDate:
          map['significantChangeApprovalDate'] as String?,
      requiresParentalConsent: map['requiresParentalConsent'] == true,
      errorCode: _asInt(map['errorCode']),
      errorMessage: map['errorMessage'] as String?,
    );
  }

  /// `SHARED`, `NOT_SHARED` o `VERIFICATION_REQUIRED` (resultado de
  /// `requestAgeSignalsAccess`).
  final String? ageSignalsStatus;

  /// `TIER_A` (autodeclarado), `TIER_B` (gestionado por padre/tutor),
  /// `TIER_C`/`TIER_D` (verificado por métodos de estimación/ID).
  final String? ageRangeSource;
  final int? ageLower;
  final int? ageUpper;
  final String? installId;

  /// `APPROVED`, `PENDING` o `DECLINED` — solo aplica en jurisdicciones con
  /// cambios significativos de edad.
  final String? significantChangeStatus;
  final String? significantChangeApprovalDate;
  final bool requiresParentalConsent;
  final int? errorCode;
  final String? errorMessage;

  bool get hasError => errorCode != null;

  /// Código compacto para decidir el mensaje de bloqueo parental, equivalente
  /// a los antiguos valores de `userStatus`.
  String? get consentReasonCode {
    if (significantChangeStatus == 'PENDING') {
      return 'SUPERVISED_APPROVAL_PENDING';
    }
    if (significantChangeStatus == 'DECLINED') {
      return 'SUPERVISED_APPROVAL_DENIED';
    }
    if (ageSignalsStatus == 'VERIFICATION_REQUIRED') {
      return 'VERIFICATION_REQUIRED';
    }
    return null;
  }

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
