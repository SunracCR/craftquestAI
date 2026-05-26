import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/navigation/app_keys.dart';
import 'package:craftquest_app/core/l10n/localized_message_holder.dart';
import 'package:craftquest_app/core/locale/locale_controller.dart';
import 'package:craftquest_app/core/theme/app_theme.dart';
import 'package:craftquest_app/core/widgets/app_connectivity_overlay.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:craftquest_app/features/auth/presentation/login_page.dart';
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

    return BlocProvider(
      create: (_) => getIt<AuthBloc>()..add(const AuthSessionChecked()),
      child: ListenableBuilder(
        listenable: localeController,
        builder: (context, _) {
          return MaterialApp(
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
            home: BlocProvider(
              create: (_) => GuestSessionCubit(
                repository: getIt<GuestRepository>(),
                tokenStorage: getIt<GuestTokenStorage>(),
              )..tryRestore(),
              child: const _AuthGate(),
            ),
          );
        },
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => current is AuthAuthenticated,
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Si había una visita guest activa, limpiarla al iniciar sesión.
          context.read<GuestSessionCubit>().reset();
          getIt<LocaleController>()
              .applyFromProfile(state.user.preferredLanguage);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is AuthInitial || authState is AuthLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (authState is AuthAuthenticated) {
            return MainShellPage(user: authState.user);
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

