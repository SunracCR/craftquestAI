class MediaAssetModel {
  const MediaAssetModel({
    required this.mediaAssetId,
    required this.url,
    this.originalFileName,
  });

  factory MediaAssetModel.fromJson(Map<String, dynamic> json) {
    return MediaAssetModel(
      mediaAssetId: json['mediaAssetId'].toString(),
      url: json['url'] as String,
      originalFileName: json['originalFileName'] as String?,
    );
  }

  final String mediaAssetId;
  final String url;
  final String? originalFileName;
}
