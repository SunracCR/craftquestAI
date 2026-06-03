import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:craftquest_app/features/auth/presentation/register_page.dart';
import 'package:craftquest_app/features/guest/presentation/bloc/guest_session_cubit.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cierra la visita guest en el servidor y vuelve a la pantalla de login.
Future<void> leaveGuestSessionAndExit(BuildContext context) async {
  await context.read<GuestSessionCubit>().leave();
  if (!context.mounted) return;
  Navigator.of(context).popUntil((route) => route.isFirst);
}

Future<bool> confirmLeaveGuestSession(
  BuildContext context,
  AppLocalizations l10n,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.guestLeaveConfirmTitle),
      content: Text(l10n.guestLeaveConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.guestLeaveAction),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Diálogo cuando el usuario agotó los canjes de código anónimos en el dispositivo.
Future<void> showAnonymousPracticeLimitDialog(
  BuildContext context,
  AppLocalizations l10n,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.guestAnonymousLimitTitle),
      content: Text(l10n.guestAnonymousLimitMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.guestAnonymousLimitLater),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.background,
          ),
          onPressed: () {
            Navigator.pop(dialogContext);
            final authBloc = context.read<AuthBloc>();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider.value(
                  value: authBloc,
                  child: const RegisterPage(),
                ),
              ),
            );
          },
          child: Text(l10n.guestAnonymousLimitSignUp),
        ),
      ],
    ),
  );
}
