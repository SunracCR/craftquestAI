import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_class_list_page.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_dashboard_page.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_welcome_overlay.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Página raíz del módulo Teacher.
/// Muestra el Dashboard como sección principal y ofrece acceso a las clases.
class TeacherHubPage extends StatefulWidget {
  const TeacherHubPage({super.key});

  @override
  State<TeacherHubPage> createState() => _TeacherHubPageState();
}

class _TeacherHubPageState extends State<TeacherHubPage> {
  int _tab = 0;
  final Set<int> _visitedTabs = {0};
  final Map<int, Widget> _sectionCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showTeacherOnboardingIfNeeded(context);
    });
  }

  Widget _sectionFor(int tabIndex) {
    return _sectionCache.putIfAbsent(tabIndex, () {
      switch (tabIndex) {
        case 0:
          return const _DashboardSection();
        case 1:
          return const _ClassesSection();
        default:
          return const SizedBox.shrink();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _tab,
        children: List.generate(
          2,
          (i) => _visitedTabs.contains(i) ? _sectionFor(i) : const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 64,
          backgroundColor: AppColors.teacherAccentSurface,
          indicatorColor: AppColors.teacherAccent.withOpacity(0.28),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? AppColors.teacherAccent : AppColors.textSecondary,
              size: 22,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.teacherAccent : AppColors.textSecondary,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() {
            _visitedTabs.add(i);
            _tab = i;
          }),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard_rounded),
              label: l10n.teacherDashboardTitle,
            ),
            NavigationDestination(
              icon: const Icon(Icons.class_outlined),
              selectedIcon: const Icon(Icons.class_rounded),
              label: l10n.teacherClassesTitle,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sección de clases dentro del hub (envuelve TeacherClassListPage).
class _ClassesSection extends StatelessWidget {
  const _ClassesSection();

  @override
  Widget build(BuildContext context) {
    return const TeacherClassListPage();
  }
}

/// Dashboard envuelto en un AppBar con título del módulo.
class _DashboardSection extends StatelessWidget {
  const _DashboardSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.teacherAccentSurface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.teacherAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school_rounded,
                  color: AppColors.teacherAccent, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.teacherTabLabel,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: const TeacherDashboardPage(),
    );
  }
}
