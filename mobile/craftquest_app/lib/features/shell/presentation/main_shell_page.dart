import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/widgets/user_avatar.dart';
import 'package:craftquest_app/features/auth/data/models/auth_models.dart';
import 'package:craftquest_app/features/home/presentation/home_page.dart';
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

  static const int _prepTabIndex = 1;

  bool get _isTeacher => widget.user.roles.contains('teacher');

  @override
  void didUpdateWidget(covariant MainShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasTeacher = oldWidget.user.roles.contains('teacher');
    if (wasTeacher && !_isTeacher) {
      if (_index == 2) {
        setState(() => _index = 0);
      } else if (_index > 2) {
        setState(() => _index = _index - 1);
      }
    }
  }

  void _goToPrepTab() => setState(() => _index = _prepTabIndex);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final pages = <Widget>[
      HomePage(
        key: ValueKey(widget.user.userId),
        user: widget.user,
        onOpenPrepPlus: _goToPrepTab,
      ),
      const PrepPlusHubPage(),
      if (_isTeacher) const TeacherHubPage(),
      ProfilePage(user: widget.user),
    ];

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

    final safeIndex = _index.clamp(0, pages.length - 1);
    final isTeacherTab = _isTeacher && safeIndex == 2;
    final isPrepTab = safeIndex == _prepTabIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: safeIndex,
        children: pages,
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
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: destinations,
        ),
      ),
    );
  }
}
