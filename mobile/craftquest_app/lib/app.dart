import 'dart:async';

import 'package:craftquest_app/core/compliance/parental_consent_gate.dart';
import 'package:craftquest_app/core/auth/session_expired_notifier.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/l10n/localized_message_holder.dart';
import 'package:craftquest_app/core/navigation/app_keys.dart';
import 'package:craftquest_app/core/navigation/web_entry_url_cleanup.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/locale/locale_controller.dart';
import 'package:craftquest_app/core/theme/app_theme.dart';
import 'package:craftquest_app/core/widgets/app_connectivity_overlay.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:craftquest_app/features/auth/presentation/join_launch.dart';
import 'package:craftquest_app/features/auth/data/models/auth_models.dart';
import 'package:craftquest_app/features/auth/presentation/account_link_launch.dart';
import 'package:craftquest_app/features/auth/presentation/login_page.dart';
import 'package:craftquest_app/features/auth/presentation/reset_password_page.dart';
import 'package:craftquest_app/features/auth/presentation/verify_email_page.dart';
import 'package:craftquest_app/features/profile/presentation/confirm_password_change_page.dart';
import 'package:craftquest_app/features/guest/data/guest_repository.dart';
import 'package:craftquest_app/features/guest/data/guest_token_storage.dart';
import 'package:craftquest_app/features/guest/presentation/bloc/guest_session_cubit.dart';
import 'package:craftquest_app/features/guest/presentation/guest_code_page.dart';
import 'package:craftquest_app/features/guest/presentation/guest_shell_page.dart';
import 'package:craftquest_app/core/services/push_notification_service.dart';
import 'package:craftquest_app/features/notifications/presentation/notifications_cubit.dart';
import 'package:craftquest_app/features/sharing/presentation/redeem_code_page.dart';
import 'package:craftquest_app/features/shell/presentation/main_shell_page.dart';
import 'package:craftquest_app/core/services/deep_link_service.dart';
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
        BlocProvider.value(
          value: getIt<NotificationsCubit>(),
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
            home: const ParentalConsentGate(
              child: _SessionExpiredListener(child: _AuthGate()),
            ),
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

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final _handledJoinCodes = <String>{};
  final _handledAccountLinks = <String>{};

  @override
  void initState() {
    super.initState();
    unawaited(
      getIt<DeepLinkService>().initialize(
        onJoinCode: (code) {
          _handledJoinCodes.remove(code);
          _scheduleDeepLinkRoute();
        },
        onAccountLink: (_) => _scheduleDeepLinkRoute(),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleDeepLinkRoute());
  }

  void _resetEntryDeepLinkState() {
    _handledJoinCodes.clear();
    _handledAccountLinks.clear();
    getIt<DeepLinkService>().clearPendingLinks();
    clearWebEntryDeepLinkUrl();
  }

  void _scheduleDeepLinkRoute() {
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _routePendingDeepLinksIfReady();
      }
    });
  }

  void _routePendingDeepLinksIfReady() {
    final deepLinkService = getIt<DeepLinkService>();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthInitial || authState is AuthLoading) {
      return;
    }

    final accountLink =
        deepLinkService.pendingAccountLink ?? readWebAccountLink();
    if (accountLink != null) {
      final linkKey = '${accountLink.kind.name}:${accountLink.token}';
      if (!_handledAccountLinks.contains(linkKey)) {
        _handledAccountLinks.add(linkKey);
        deepLinkService.consumePendingAccountLink();
        rootNavigatorKey.currentState?.push(
          MaterialPageRoute<void>(
            builder: (_) => _accountLinkPage(accountLink),
          ),
        );
        return;
      }
    }

    final code = deepLinkService.pendingJoinCode ?? readWebJoinCode();
    if (code == null || _handledJoinCodes.contains(code)) {
      return;
    }

    final resetToken = readWebPasswordResetToken();
    if (resetToken != null) {
      return;
    }

    _handledJoinCodes.add(code);
    deepLinkService.consumePendingJoinCode();

    if (authState is AuthAuthenticated) {
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => RedeemCodePage(
            initialCode: code,
            autoRedeem: true,
          ),
        ),
      );
      return;
    }

    final guestState = context.read<GuestSessionCubit>().state;
    if (guestState.isActive) {
      return;
    }

    rootNavigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => GuestCodePage(initialCode: code),
      ),
    );
  }

  Widget _accountLinkPage(PendingAccountLink link) {
    switch (link.kind) {
      case AccountLinkKind.verifyEmail:
        return VerifyEmailPage(initialToken: link.token);
      case AccountLinkKind.resetPassword:
        return ResetPasswordPage(initialToken: link.token);
      case AccountLinkKind.confirmPasswordChange:
        return ConfirmPasswordChangePage(initialToken: link.token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              (current is AuthUnauthenticated &&
                  previous is! AuthAuthenticated) ||
              (current is AuthAuthenticated && previous is AuthLoading),
          listener: (context, _) => _scheduleDeepLinkRoute(),
        ),
        BlocListener<GuestSessionCubit, GuestSessionState>(
          listenWhen: (previous, current) =>
              previous.isActive != current.isActive,
          listener: (context, _) => _scheduleDeepLinkRoute(),
        ),
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              current is AuthAuthenticated &&
              (previous is AuthUnauthenticated ||
                  previous is AuthFailure ||
                  previous is AuthEmailVerificationPending),
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
              unawaited(getIt<NotificationsCubit>().refreshUnreadCount());
              unawaited(getIt<PushNotificationService>().onAuthenticated());
              // Tras limpiar la pila de login, abrir join links pendientes.
              _scheduleDeepLinkRoute();
            });
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              previous is AuthAuthenticated &&
              current is AuthUnauthenticated,
          listener: (context, _) {
            _resetEntryDeepLinkState();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
            });
            unawaited(
              context.read<GuestSessionCubit>().clearLocalSession(),
            );
            unawaited(getIt<NotificationsCubit>().reset());
            unawaited(getIt<PushNotificationService>().onLogout());
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
            return _AuthenticatedShell(user: authState.user);
          }

          final accountLink = readWebAccountLink();
          if (accountLink != null) {
            return _accountLinkPage(accountLink);
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

class _AuthenticatedShell extends StatefulWidget {
  const _AuthenticatedShell({required this.user});

  final UserProfileModel user;

  @override
  State<_AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends State<_AuthenticatedShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(getIt<NotificationsCubit>().refreshUnreadCount());
      unawaited(getIt<PushNotificationService>().onAuthenticated());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(getIt<NotificationsCubit>().refreshUnreadCount());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainShellPage(user: widget.user);
  }
}

