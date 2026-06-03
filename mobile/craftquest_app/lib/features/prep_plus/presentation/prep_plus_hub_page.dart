import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_models.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_repository.dart';
import 'package:craftquest_app/features/prep_plus/presentation/prep_plus_category_page.dart';
import 'package:craftquest_app/features/prep_plus/presentation/prep_plus_my_accesses_page.dart';
import 'package:craftquest_app/features/prep_plus/presentation/widgets/prep_plus_country_flag.dart';
import 'package:craftquest_app/features/prep_plus/presentation/widgets/prep_plus_hub_cards.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class PrepPlusHubPage extends StatefulWidget {
  const PrepPlusHubPage({super.key});

  @override
  State<PrepPlusHubPage> createState() => _PrepPlusHubPageState();
}

class _PrepPlusHubPageState extends State<PrepPlusHubPage> {
  final _repository = getIt<PrepPlusRepository>();
  List<PrepCategoryModel> _roots = [];
  PrepMyAccessesModel? _accesses;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.getCategories(),
        _repository.getMyAccesses(),
      ]);
      if (!mounted) return;
      setState(() {
        _roots = results[0] as List<PrepCategoryModel>;
        _accesses = results[1] as PrepMyAccessesModel;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _repository.mapError(e);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.genericMessage();
        _loading = false;
      });
    }
  }

  List<PrepCategoryModel> get _geographicRoots =>
      _roots.where((c) => c.isGeographic).toList();

  PrepCategoryModel? get _internationalRoot {
    for (final root in _roots) {
      if (root.slug == 'internacional' ||
          (root.isThematic && root.parentCategoryId == null)) {
        return root;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeCount = _accesses?.active.length ?? 0;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.prepPlusScreenTitle),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? AppErrorView(
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: _load,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: AppSpacing.listBottom,
                    children: [
                      PrepPlusHubHero(subtitle: l10n.prepPlusScreenSubtitle),
                      if (activeCount > 0) ...[
                        const SizedBox(height: AppSpacing.md),
                        PrepPlusMyAccessesTile(
                          activeCount: activeCount,
                          onTap: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const PrepPlusMyAccessesPage(),
                                  ),
                                )
                                .then((_) => _load());
                          },
                        ),
                      ],
                      PrepPlusSectionHeader(
                        title: l10n.prepPlusByCountrySection,
                        icon: Icons.flag_rounded,
                      ),
                      if (_geographicRoots.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < _geographicRoots.length; i++) ...[
                                if (i > 0) const SizedBox(height: AppSpacing.sm),
                                PrepPlusCountryCard(
                                  category: _geographicRoots[i],
                                  onTap: () => _openRoot(
                                    context,
                                    _geographicRoots[i],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      if (_internationalRoot != null) ...[
                        PrepPlusSectionHeader(
                          title: l10n.prepPlusInternationalSection,
                          icon: Icons.public_rounded,
                        ),
                        PrepPlusInternationalTile(
                          category: _internationalRoot!,
                          onTap: () => _openRoot(
                            context,
                            _internationalRoot!,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
    );
  }

  void _openRoot(BuildContext context, PrepCategoryModel root) {
    if (root.children.isEmpty) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PrepPlusCategoryPickerPage(root: root),
      ),
    );
  }
}

/// Elige subcategoría dentro de un país o Internacional.
class PrepPlusCategoryPickerPage extends StatelessWidget {
  const PrepPlusCategoryPickerPage({super.key, required this.root});

  final PrepCategoryModel root;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: root.name),
      body: ListView(
        padding: AppSpacing.listBottom,
        children: [
          if (root.isGeographic && root.countryCode != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  PrepPlusCountryFlag(countryCode: root.countryCode, size: 40),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      root.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          for (final child in root.children)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                0,
              ),
              child: AppSectionCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  title: Text(child.name),
                  subtitle: Text(
                    l10n.prepPlusCategoryItemCount(child.publishedItemCount),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PrepPlusCategoryPage(
                          category: child,
                          showInstitutionFilter: root.isGeographic,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
