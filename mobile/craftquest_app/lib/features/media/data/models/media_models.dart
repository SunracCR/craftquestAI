import 'dart:convert';

import 'package:dio/dio.dart';

class MediaAssetModel {
  const MediaAssetModel({
    required this.mediaAssetId,
    required this.url,
    this.originalFileName,
  });

  factory MediaAssetModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['mediaAssetId'] ?? json['MediaAssetId'];
    if (rawId == null || rawId.toString().isEmpty) {
      throw const FormatException('mediaAssetId missing in upload response');
    }
    final rawUrl = json['url'] ?? json['Url'];
    if (rawUrl == null || rawUrl.toString().isEmpty) {
      throw const FormatException('url missing in upload response');
    }
    return MediaAssetModel(
      mediaAssetId: rawId.toString(),
      url: rawUrl.toString(),
      originalFileName: (json['originalFileName'] ?? json['OriginalFileName'])
          as String?,
    );
  }

  factory MediaAssetModel.fromUploadResponse(Response<dynamic> response) {
    final data = _coerceResponseBody(response.data);
    if (data != null) {
      return MediaAssetModel.fromJson(data);
    }

    final location =
        response.headers.value('location') ?? response.headers.value('Location');
    if (location != null && location.isNotEmpty) {
      final uri = Uri.tryParse(location.startsWith('/')
          ? 'http://local$location'
          : location);
      if (uri != null) {
        final segments = uri.pathSegments;
        final fileIndex = segments.lastIndexOf('file');
        if (fileIndex > 0) {
          final id = segments[fileIndex - 1];
          final path = uri.hasScheme
              ? '${uri.origin}${uri.path}'
              : (location.startsWith('/') ? location : '/$location');
          return MediaAssetModel(
            mediaAssetId: id,
            url: path,
          );
        }
      }
    }

    throw FormatException(
      'Invalid media upload response (status ${response.statusCode})',
    );
  }

  static Map<String, dynamic>? _coerceResponseBody(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is String && data.trim().isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }
    return null;
  }

  final String mediaAssetId;
  final String url;
  final String? originalFileName;

  Map<String, dynamic> toJson() => {
        'mediaAssetId': mediaAssetId,
        'url': url,
        if (originalFileName != null) 'originalFileName': originalFileName,
      };
}
