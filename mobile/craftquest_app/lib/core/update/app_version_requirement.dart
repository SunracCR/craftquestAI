/// Requisito de versión mínima devuelto por `GET /api/app-version`.
class AppVersionRequirement {
  const AppVersionRequirement({
    required this.minSupportedVersion,
    this.latestVersion,
    required this.updateUrl,
    this.message,
  });

  factory AppVersionRequirement.fromJson(Map<String, dynamic> json) {
    return AppVersionRequirement(
      minSupportedVersion: json['minSupportedVersion'] as String,
      latestVersion: json['latestVersion'] as String?,
      updateUrl: json['updateUrl'] as String,
      message: json['message'] as String?,
    );
  }

  final String minSupportedVersion;
  final String? latestVersion;
  final String updateUrl;
  final String? message;
}
