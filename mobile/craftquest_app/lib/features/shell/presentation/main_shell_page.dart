import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/widgets/user_avatar.dart';
import 'package:craftquest_app/features/auth/data/models/auth_models.dart';
import 'package:craftquest_app/features/home/presentation/home_page.dart';
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

  bool get _isTeacher => widget.user.roles.contains('teacher');

  @override
  void didUpdateWidget(covariant MainShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el usuario perdió el rol teacher y estaba en el tab Teacher, volvemos a Home.
    final wasTeacher = oldWidget.user.roles.contains('teacher');
    if (wasTeacher && !_isTeacher && _index == 1) {
      setState(() => _index = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final pages = <Widget>[
      HomePage(user: widget.user),
      if (_isTeacher) const TeacherHubPage(),
      ProfilePage(user: widget.user),
    ];

    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home_rounded),
        label: l10n.navHomeLabel,
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

    // Clamp index in case the teacher tab was added/removed
    final safeIndex = _index.clamp(0, pages.length - 1);

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
          indicatorColor: _isTeacher && safeIndex == 1
              ? AppColors.teacherAccent.withOpacity(0.28)
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
