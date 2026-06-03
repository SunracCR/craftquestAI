import 'package:craftquest_app/core/utils/media_request_headers.dart';
import 'package:flutter/material.dart';

/// Imagen de la API de media con cabeceras de autenticación o invitado.
class CraftQuestNetworkImage extends StatelessWidget {
  const CraftQuestNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  final String imageUrl;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>?>(
      future: MediaRequestHeaders.build(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final headers = snapshot.data;
        return Image.network(
          imageUrl,
          key: ValueKey('$imageUrl|${headers?['Authorization'] ?? headers?['X-Guest-Token']}'),
          fit: fit,
          headers: headers,
          filterQuality: FilterQuality.high,
          errorBuilder: errorBuilder,
        );
      },
    );
  }
}
