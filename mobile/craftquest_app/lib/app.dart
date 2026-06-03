import 'dart:async';

import 'package:craftquest_app/core/compliance/parental_consent_gate.dart';
import 'package:craftquest_app/core/auth/session_expired_notifier.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/l10n/localized_message_holder.dart';
import 'package:craftquest_app/core/navigation/app_keys.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/locale/locale_controller.dart';
import 'package:craftquest_app/core/theme/app_theme.dart';
import 'package:craftquest_app/core/widgets/app_connectivity_overlay.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:craftquest_app/features/auth/presentation/login_page.dart';
import 'package:craftquest_app/features/auth/presentation/password_reset_launch.dart';
import 'package:craftquest_app/features/auth/presentation/reset_password_page.dart';
import 'package:craftquest_app/features/guest/data/guest_repository.dart';
import 'package:craftquest_app/features/guest/data/guest_token_storage.dart';
import 'package:craftquest_app/features/guest/presentation/bloc/guest_session_cubit.dart';
import 'package:craftquest_app/features/guest/presentation/guest_shell_page.dart';
import 'package:craftquest_app/features/shell/presentation/main_shell_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class CraftQuestApp extends StatelessWidget {
  const CraftQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeController = getIt<LocaleController>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<AuthBloc>()..add(const AuthSessionChecked()),
        ),
        BlocProvider(
          create: (_) => GuestSessionCubit(
            repository: getIt<GuestRepository>(),
            tokenStorage: getIt<GuestTokenStorage>(),
          )..tryRestore(),
        ),
      ],
      child: ListenableBuilder(
        listenable: localeController,
        builder: (context, _) {
          return MaterialApp(
            navigatorKey: rootNavigatorKey,
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.appTitle,
            locale: localeController.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.dark,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.dark,
            builder: (context, child) {
              LocalizedMessageHolder.update(AppLocalizations.of(context));
              return AppConnectivityOverlay(child: child);
            },
            home: const ParentalConsentGate(child: _AuthGate()),
          );
        },
      ),
    );
  }
}

class _SessionExpiredListener extends StatefulWidget {
  const _SessionExpiredListener({required this.child});

  final Widget child;

  @override
  State<_SessionExpiredListener> createState() =>
      _SessionExpiredListenerState();
}

class _SessionExpiredListenerState extends State<_SessionExpiredListener> {
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = getIt<SessionExpiredNotifier>().stream.listen((_) {
      if (!mounted) {
        return;
      }
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        return;
      }

      final message = LocalizedMessageHolder.current?.errorSessionExpired ??
          'Tu sesión ha caducado. Vuelve a iniciar sesión e inténtalo de nuevo.';
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
      context.read<AuthBloc>().add(const AuthSessionExpired());
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (_, current) => current is AuthAuthenticated,
          listener: (context, state) {
            if (state is! AuthAuthenticated) {
              return;
            }
            final user = state.user;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Register/login guest hacen push sobre el navigator raíz; hay que
              // sacarlos aunque el home ya sea MainShellPage.
              rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
              if (!context.mounted) {
                return;
              }
              unawaited(
                context.read<GuestSessionCubit>().clearLocalSession(),
              );
              unawaited(
                getIt<LocaleController>().applyFromProfile(
                  user.preferredLanguage,
                ),
              );
            });
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              previous is AuthAuthenticated &&
              current is AuthUnauthenticated,
          listener: (context, _) {
            unawaited(
              context.read<GuestSessionCubit>().clearLocalSession(),
            );
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          // AuthLoading solo al arranque (AuthSessionChecked). OAuth/registro no lo usan.
          if (authState is AuthInitial || authState is AuthLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (authState is AuthAuthenticated) {
            return MainShellPage(user: authState.user);
          }

          final resetToken = readWebPasswordResetToken();
          if (resetToken != null) {
            return ResetPasswordPage(initialToken: resetToken);
          }

          // No autenticado: comprobar si hay visita guest activa.
          return BlocBuilder<GuestSessionCubit, GuestSessionState>(
            builder: (context, guestState) {
              if (guestState.isActive && guestState.visit != null) {
                return GuestShellPage(visit: guestState.visit!);
              }
              return const LoginPage();
            },
          );
        },
      ),
    );
  }
}

