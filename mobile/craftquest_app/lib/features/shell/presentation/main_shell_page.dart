import 'dart:async';

import 'package:craftquest_app/core/billing/checkout_refresh_notifier.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/services/app_warmup_service.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/widgets/user_avatar.dart';
import 'package:craftquest_app/features/auth/data/models/auth_models.dart';
import 'package:craftquest_app/features/home/presentation/home_page.dart';
import 'package:craftquest_app/features/notifications/presentation/notifications_cubit.dart';
import 'package:craftquest_app/features/prep_plus/presentation/prep_plus_hub_page.dart';
import 'package:craftquest_app/features/profile/presentation/profile_page.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_hub_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key, required this.user});

  final UserProfileModel user;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _index = 0;
  final Set<int> _visitedTabs = {0};
  final Map<int, Widget> _pageCache = {};
  late final CheckoutRefreshNotifier _checkoutRefresh;

  static const int _prepTabIndex = 1;
  static const int _teacherTabIndex = 2;

  bool get _isTeacher => widget.user.roles.contains('teacher');

  int get _pageCount => _isTeacher ? 4 : 3;

  int get _profileTabIndex => _isTeacher ? 3 : 2;

  @override
  void initState() {
    super.initState();
    _checkoutRefresh = getIt<CheckoutRefreshNotifier>()
      ..addListener(_onCheckoutCompleted);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      getIt<AppWarmupService>().start(
        prefetchTeacherDashboard: _isTeacher,
      );
      if (_isTeacher) {
        setState(() => _visitedTabs.add(_teacherTabIndex));
        _pageFor(_teacherTabIndex);
      }
    });
  }

  @override
  void dispose() {
    _checkoutRefresh.removeListener(_onCheckoutCompleted);
    super.dispose();
  }

  void _onCheckoutCompleted() {
    if (!mounted) {
      return;
    }
    setState(() {
      _pageCache.remove(0);
      _pageCache.remove(_profileTabIndex);
      _index = 0;
    });
  }

  @override
  void didUpdateWidget(covariant MainShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasTeacher = oldWidget.user.roles.contains('teacher');
    if (!wasTeacher && _isTeacher) {
      _pageCache.clear();
      _visitedTabs
        ..clear()
        ..add(0)
        ..add(_teacherTabIndex);
      getIt<AppWarmupService>().start(prefetchTeacherDashboard: true);
      if (_index != 0) {
        setState(() => _index = 0);
      }
    } else if (wasTeacher && !_isTeacher) {
      _pageCache.clear();
      _visitedTabs.remove(_teacherTabIndex);
      if (_index == _teacherTabIndex) {
        setState(() => _index = 0);
      } else if (_index > _teacherTabIndex) {
        setState(() => _index = _index - 1);
      }
    } else if (oldWidget.user != widget.user) {
      _pageCache.remove(0);
      _pageCache[_profileTabIndex] = ProfilePage(user: widget.user);
    }
  }

  void _goToPrepTab() => _selectTab(_prepTabIndex);

  void _selectTab(int value) {
    if (value == 0) {
      unawaited(getIt<NotificationsCubit>().refreshUnreadCount());
    }
    setState(() {
      _visitedTabs.add(value);
      _index = value;
    });
  }

  Widget _pageFor(int tabIndex) {
    return _pageCache.putIfAbsent(tabIndex, () {
      switch (tabIndex) {
        case 0:
          return HomePage(
            key: ValueKey(widget.user.userId),
            user: widget.user,
            onOpenPrepPlus: _goToPrepTab,
          );
        case 1:
          return const PrepPlusHubPage();
        case 2:
          return _isTeacher
              ? const TeacherHubPage()
              : ProfilePage(user: widget.user);
        case 3:
          return ProfilePage(user: widget.user);
        default:
          return const SizedBox.shrink();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home_rounded),
        label: l10n.navHomeLabel,
      ),
      NavigationDestination(
        icon: const Icon(Icons.menu_book_outlined),
        selectedIcon: const Icon(Icons.menu_book_rounded),
        label: l10n.navPrepPlusLabel,
      ),
      if (_isTeacher)
        NavigationDestination(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.school_outlined),
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.teacherAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          selectedIcon: const Icon(Icons.school_rounded),
          label: l10n.teacherTabLabel,
        ),
      NavigationDestination(
        icon: UserAvatar(avatarId: widget.user.avatarId, size: 26),
        selectedIcon: UserAvatar(
          avatarId: widget.user.avatarId,
          size: 28,
          selected: true,
        ),
        label: l10n.navProfileLabel,
      ),
    ];

    final safeIndex = _index.clamp(0, _pageCount - 1);
    final isTeacherTab = _isTeacher && safeIndex == 2;
    final isPrepTab = safeIndex == _prepTabIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: safeIndex,
        children: List.generate(
          _pageCount,
          (i) => _visitedTabs.contains(i) ? _pageFor(i) : const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 72,
          backgroundColor: AppColors.surface,
          indicatorColor: isTeacherTab
              ? AppColors.teacherAccent.withOpacity(0.28)
              : isPrepTab
                  ? AppColors.accentGold.withOpacity(0.28)
                  : AppColors.accentMint.withOpacity(0.28),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              size: 24,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: _selectTab,
          destinations: destinations,
        ),
      ),
    );
  }
}
