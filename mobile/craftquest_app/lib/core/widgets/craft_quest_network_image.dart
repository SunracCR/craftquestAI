import 'package:craftquest_app/core/utils/media_request_headers.dart';
import 'package:flutter/material.dart';

/// Imagen de la API de media con cabeceras de autenticación o invitado.
class CraftQuestNetworkImage extends StatefulWidget {
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
  State<CraftQuestNetworkImage> createState() => _CraftQuestNetworkImageState();
}

class _CraftQuestNetworkImageState extends State<CraftQuestNetworkImage> {
  Map<String, String>? _headers;
  var _resolvingHeaders = true;

  @override
  void initState() {
    super.initState();
    _resolveHeaders();
  }

  Future<void> _resolveHeaders() async {
    final cached = MediaRequestHeaders.cachedOrNull;
    if (cached != null) {
      if (mounted) {
        setState(() {
          _headers = cached;
          _resolvingHeaders = false;
        });
      }
      return;
    }

    final headers = await MediaRequestHeaders.buildCached();
    if (!mounted) return;
    setState(() {
      _headers = headers;
      _resolvingHeaders = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_resolvingHeaders) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final headers = _headers;
    return Image.network(
      widget.imageUrl,
      key: ValueKey(
        '${widget.imageUrl}|${headers?['Authorization'] ?? headers?['X-Guest-Token']}',
      ),
      fit: widget.fit,
      headers: headers,
      filterQuality: FilterQuality.high,
      errorBuilder: widget.errorBuilder,
    );
  }
}
