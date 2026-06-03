import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/prep_plus/presentation/admin/prep_plus_admin_categories_page.dart';
import 'package:craftquest_app/features/prep_plus/presentation/admin/prep_plus_admin_items_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PrepPlusAdminHubPage extends StatelessWidget {
  const PrepPlusAdminHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.prepAdminHubTitle),
      body: ListView(
        padding: AppSpacing.listBottom,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l10n.prepAdminHubSubtitle,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppSectionCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.account_tree_outlined,
                        color: AppColors.accentCool),
                    title: Text(l10n.prepAdminCategoriesAction),
                    subtitle: Text(l10n.prepAdminCategoriesSubtitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PrepPlusAdminCategoriesPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined,
                        color: AppColors.accentGold),
                    title: Text(l10n.prepAdminCatalogAction),
                    subtitle: Text(l10n.prepAdminCatalogSubtitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PrepPlusAdminItemsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
