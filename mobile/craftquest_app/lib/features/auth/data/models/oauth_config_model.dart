class OAuthConfigModel {
  const OAuthConfigModel({
    this.googleWebClientId,
    this.isGoogleConfigured = false,
    this.isAppleConfigured = false,
    this.appleServicesId,
    this.appleWebRedirectUri,
    this.isAppleWebConfigured = false,
  });

  factory OAuthConfigModel.fromJson(Map<String, dynamic> json) {
    return OAuthConfigModel(
      googleWebClientId: json['googleWebClientId'] as String?,
      isGoogleConfigured: json['isGoogleConfigured'] as bool? ?? false,
      isAppleConfigured: json['isAppleConfigured'] as bool? ?? false,
      appleServicesId: json['appleServicesId'] as String?,
      appleWebRedirectUri: json['appleWebRedirectUri'] as String?,
      isAppleWebConfigured: json['isAppleWebConfigured'] as bool? ?? false,
    );
  }

  final String? googleWebClientId;
  final bool isGoogleConfigured;
  final bool isAppleConfigured;
  final String? appleServicesId;
  final String? appleWebRedirectUri;
  final bool isAppleWebConfigured;
}
