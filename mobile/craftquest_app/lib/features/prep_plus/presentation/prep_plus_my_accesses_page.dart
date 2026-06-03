import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_list_entry_card.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_models.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_repository.dart';
import 'package:craftquest_app/features/prep_plus/presentation/prep_plus_item_detail_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrepPlusMyAccessesPage extends StatefulWidget {
  const PrepPlusMyAccessesPage({super.key});

  @override
  State<PrepPlusMyAccessesPage> createState() => _PrepPlusMyAccessesPageState();
}

class _PrepPlusMyAccessesPageState extends State<PrepPlusMyAccessesPage>
    with SingleTickerProviderStateMixin {
  final _repository = getIt<PrepPlusRepository>();
  late final TabController _tabController;
  PrepMyAccessesModel? _accesses;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repository.getMyAccesses();
      if (!mounted) return;
      setState(() {
        _accesses = data;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: AppBar(
        title: Text(l10n.prepPlusMyAccessesTitle),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentGold,
          labelColor: AppColors.accentGold,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: l10n.prepPlusTabActive),
            Tab(text: l10n.prepPlusTabExpired),
          ],
        ),
      ),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? AppErrorView(
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: _load,
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _AccessList(
                      items: _accesses?.active ?? [],
                      emptyMessage: l10n.prepPlusMyAccessesActiveEmpty,
                      onRefresh: _load,
                      expired: false,
                    ),
                    _AccessList(
                      items: _accesses?.expired ?? [],
                      emptyMessage: l10n.prepPlusMyAccessesExpiredEmpty,
                      onRefresh: _load,
                      expired: true,
                    ),
                  ],
                ),
    );
  }
}

class _AccessList extends StatelessWidget {
  const _AccessList({
    required this.items,
    required this.emptyMessage,
    required this.onRefresh,
    required this.expired,
  });

  final List<PrepMyAccessItemModel> items;
  final String emptyMessage;
  final Future<void> Function() onRefresh;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFmt = DateFormat.yMMMd(Localizations.localeOf(context).toString());

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.4,
              child: AppEmptyView(
                message: emptyMessage,
                icon: Icons.lock_clock_outlined,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: AppSpacing.listBottom,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              0,
            ),
            child: AppListEntryCard(
              title: item.title,
              subtitle: expired
                  ? l10n.prepPlusExpiredOn(dateFmt.format(item.expiresAt.toLocal()))
                  : l10n.prepPlusExpiresOn(dateFmt.format(item.expiresAt.toLocal())),
              accentColor: expired ? AppColors.textSecondary : AppColors.accentMint,
              leadingIcon: expired
                  ? Icons.history_rounded
                  : Icons.play_circle_outline_rounded,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PrepPlusItemDetailPage(
                      catalogItemId: item.catalogItemId,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
