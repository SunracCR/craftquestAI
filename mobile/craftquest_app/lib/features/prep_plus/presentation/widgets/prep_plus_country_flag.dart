import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/utils/country_flag_utils.dart';
import 'package:flutter/material.dart';

/// Bandera del país (red CDN) con respaldo emoji si falla la carga.
class PrepPlusCountryFlag extends StatelessWidget {
  const PrepPlusCountryFlag({
    super.key,
    required this.countryCode,
    this.size = 44,
    this.showBorder = true,
  });

  final String? countryCode;
  final double size;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final url = CountryFlagUtils.imageUrl(countryCode, width: 160);
    final emoji = CountryFlagUtils.emoji(countryCode);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceHighlight,
        border: showBorder
            ? Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.25),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? Center(
              child: Text(emoji, style: TextStyle(fontSize: size * 0.52)),
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorBuilder: (_, __, ___) => Center(
                child: Text(emoji, style: TextStyle(fontSize: size * 0.52)),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return child;
                }
                return Center(
                  child: SizedBox(
                    width: size * 0.35,
                    height: size * 0.35,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accentGold.withValues(alpha: 0.8),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
