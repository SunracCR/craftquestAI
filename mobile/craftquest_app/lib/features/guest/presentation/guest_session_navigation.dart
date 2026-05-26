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
