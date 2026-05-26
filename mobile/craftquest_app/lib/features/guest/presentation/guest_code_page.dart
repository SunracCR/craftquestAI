import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_brand_header.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/guest/presentation/bloc/guest_session_cubit.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GuestCodePage extends StatefulWidget {
  const GuestCodePage({super.key});

  @override
  State<GuestCodePage> createState() => _GuestCodePageState();
}

class _GuestCodePageState extends State<GuestCodePage> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<GuestSessionCubit>().enter(_codeController.text.trim());
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && mounted) {
      _codeController.text = data!.text!.trim().toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<GuestSessionCubit, GuestSessionState>(
      listenWhen: (previous, current) =>
          (current.isActive && !previous.isActive) ||
          (current.isError && !previous.isError),
      listener: (context, state) {
        if (state.isActive) {
          // La visita quedó activa en _AuthGate; cerrar esta ruta para mostrar GuestShellPage.
          Navigator.of(context).pop();
          return;
        }
        if (state.isError) {
          context.showErrorSnackBar(
            state.errorMessage ?? l10n.genericRequestErrorMessage,
          );
        }
      },
      child: BlocBuilder<GuestSessionCubit, GuestSessionState>(
        builder: (context, state) {
          final isLoading = state.isLoading;

          return EdgeAwareScaffold(
            appBar: craftQuestAppBar(title: l10n.guestCodeTitle),
            bottomBar: AppBottomActionBar(
              children: [
                AppGradientPrimaryButton(
                  label: l10n.guestCodeAction,
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _submit,
                ),
              ],
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: AppSpacing.pageVertical,
                children: [
                  AppBrandHeader(
                    title: l10n.guestCodeTitle,
                    subtitle: l10n.guestCodeSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextFormField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: l10n.guestCodeLabel,
                      hintText: 'CQ-000000',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.content_paste_rounded),
                        tooltip: l10n.guestCodePasteTooltip,
                        onPressed: isLoading ? null : _paste,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.guestCodeRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Text(
                      l10n.guestEphemeralNotice,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
