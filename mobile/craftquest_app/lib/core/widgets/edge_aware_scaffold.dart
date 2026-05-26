import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Scaffold edge-to-edge con AppBar y barra inferior opcional.
class EdgeAwareScaffold extends StatelessWidget {
  const EdgeAwareScaffold({
    super.key,
    required this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomBar,
    this.resizeToAvoidBottomInset = true,
  });

  final PreferredSizeWidget appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomBar;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final content = bottomBar == null
        ? body
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: body),
              bottomBar!,
            ],
          );

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: false,
      appBar: appBar,
      body: SafeArea(
        bottom: bottomBar == null,
        child: content,
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation:
          floatingActionButtonLocation ?? FloatingActionButtonLocation.endFloat,
    );
  }
}

/// AppBar estándar CraftQuest con título y acciones alineados.
PreferredSizeWidget craftQuestAppBar({
  required String title,
  List<Widget>? actions,
  bool automaticallyImplyLeading = true,
}) {
  return AppBar(
    automaticallyImplyLeading: automaticallyImplyLeading,
    title: Text(title),
    actions: actions,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.textSecondary.withValues(alpha: 0.15),
      ),
    ),
  );
}

/// FAB extendido con margen inferior seguro.
class AppExtendedFab extends StatelessWidget {
  const AppExtendedFab({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        right: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
