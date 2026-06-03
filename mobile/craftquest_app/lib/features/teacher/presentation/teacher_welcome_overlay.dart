import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/utils/email_utils.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:craftquest_app/features/teacher/data/teacher_class_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _legacyPrefKey = 'teacher_onboarding_done';

String _prefKeyForUser(String userId) => 'teacher_onboarding_done_$userId';

/// Comprueba si el onboarding ya fue completado para este usuario.
Future<bool> isTeacherOnboardingDone(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  final key = _prefKeyForUser(userId);
  if (prefs.getBool(key) == true) {
    return true;
  }

  // Migrar flag global antiguo (sin userId).
  if (prefs.getBool(_legacyPrefKey) == true) {
    await prefs.setBool(key, true);
    await prefs.remove(_legacyPrefKey);
    return true;
  }

  return false;
}

/// Marca el onboarding como completado para este usuario.
Future<void> markTeacherOnboardingDone(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_prefKeyForUser(userId), true);
  await prefs.remove(_legacyPrefKey);
}

/// Muestra el overlay de onboarding teacher si todavía no fue completado.
Future<void> showTeacherOnboardingIfNeeded(BuildContext context) async {
  final authState = context.read<AuthBloc>().state;
  if (authState is! AuthAuthenticated) return;

  final userId = authState.user.userId;
  if (await isTeacherOnboardingDone(userId)) return;

  // Si ya tiene clases (creadas fuera del onboarding), no volver a mostrar.
  try {
    final classes = await getIt<TeacherClassRepository>().listClasses();
    if (classes.isNotEmpty) {
      await markTeacherOnboardingDone(userId);
      return;
    }
  } catch (_) {
    // Si falla la API, continuar con el flujo normal de onboarding.
  }

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TeacherWelcomeOverlay(userId: userId),
  );
}

class TeacherWelcomeOverlay extends StatefulWidget {
  const TeacherWelcomeOverlay({super.key, required this.userId});

  final String userId;

  @override
  State<TeacherWelcomeOverlay> createState() => _TeacherWelcomeOverlayState();
}

class _TeacherWelcomeOverlayState extends State<TeacherWelcomeOverlay> {
  final _repo = getIt<TeacherClassRepository>();
  final _pageCtrl = PageController();
  int _step = 0;

  final _classNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _createdClassId;

  static const int _totalSteps = 3;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _classNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await markTeacherOnboardingDone(widget.userId);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _createClass() async {
    final name = _classNameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    try {
      final cls = await _repo.createClass(name: name);
      _createdClassId = cls.classId;
      _next();
    } on DioException catch (e) {
      if (mounted) context.showDioErrorSnackBar(e);
    } catch (_) {
      if (mounted) {
        context.showErrorSnackBar(
          DioErrorMapper.genericMessage(AppLocalizations.of(context)!),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _inviteStudent() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailCtrl.text.trim();
    final classId = _createdClassId;
    if (email.isEmpty || classId == null) {
      _next();
      return;
    }
    if (!EmailUtils.isValid(email)) {
      context.showErrorSnackBar(l10n.teacherClassInvalidEmailError);
      return;
    }
    setState(() => _loading = true);
    try {
      await _repo.addMemberByEmail(classId: classId, email: email);
      _next();
    } on DioException catch (e) {
      if (mounted) context.showDioErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.teacherAccentSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.school_rounded,
                            color: AppColors.teacherAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.teacherOnboardingWelcomeTitle,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            l10n.teacherOnboardingStepProgress(
                              _step + 1,
                              _totalSteps,
                            ),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / _totalSteps,
                      minHeight: 5,
                      backgroundColor:
                          AppColors.teacherAccent.withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.teacherAccent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: AppColors.surfaceHighlight, height: 1),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1CreateClass(
                    controller: _classNameCtrl,
                    onAction: _createClass,
                    loading: _loading,
                  ),
                  _Step2InviteStudent(
                    controller: _emailCtrl,
                    onAction: _inviteStudent,
                    onSkip: _next,
                    loading: _loading,
                  ),
                  _Step3Done(onFinish: _finish),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step1CreateClass extends StatelessWidget {
  const _Step1CreateClass({
    required this.controller,
    required this.onAction,
    required this.loading,
  });

  final TextEditingController controller;
  final VoidCallback onAction;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _stepIcon(Icons.class_rounded, AppColors.teacherAccent),
          const SizedBox(height: 20),
          Text(
            l10n.teacherOnboardingStep1Title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.teacherOnboardingStep1Body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.teacherOnboardingClassNameLabel,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 15),
            decoration: _inputDecoration(l10n.teacherOnboardingClassNameHint),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 32),
          _primaryButton(
            label: l10n.teacherOnboardingCreateClassAction,
            icon: Icons.arrow_forward_rounded,
            onPressed: onAction,
            loading: loading,
          ),
        ],
      ),
    );
  }
}

class _Step2InviteStudent extends StatelessWidget {
  const _Step2InviteStudent({
    required this.controller,
    required this.onAction,
    required this.onSkip,
    required this.loading,
  });

  final TextEditingController controller;
  final VoidCallback onAction;
  final VoidCallback onSkip;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _stepIcon(Icons.person_add_rounded, AppColors.accentCool),
          const SizedBox(height: 20),
          Text(
            l10n.teacherOnboardingStep2Title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.teacherOnboardingStep2Body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.teacherOnboardingStudentEmailLabel,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 15),
            decoration:
                _inputDecoration(l10n.teacherOnboardingStudentEmailHint),
          ),
          const SizedBox(height: 32),
          _primaryButton(
            label: l10n.teacherOnboardingInviteAction,
            icon: Icons.arrow_forward_rounded,
            onPressed: onAction,
            loading: loading,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary),
              child: Text(
                l10n.teacherOnboardingSkipAction,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step3Done extends StatelessWidget {
  const _Step3Done({required this.onFinish});

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accentMint.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.accentMint, size: 44),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.teacherOnboardingStep3Title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 26,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.teacherOnboardingStep3Body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _primaryButton(
            label: l10n.teacherOnboardingGoToDashboardAction,
            icon: Icons.dashboard_rounded,
            onPressed: onFinish,
            loading: false,
          ),
        ],
      ),
    );
  }
}

Widget _stepIcon(IconData icon, Color color) => Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 28),
    );

InputDecoration _inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

Widget _primaryButton({
  required String label,
  required IconData icon,
  required VoidCallback onPressed,
  required bool loading,
}) =>
    SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teacherAccent,
          foregroundColor: AppColors.background,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.background))
            : Icon(icon, size: 18),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        onPressed: loading ? null : onPressed,
      ),
    );
