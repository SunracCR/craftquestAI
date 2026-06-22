import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/features/sharing/data/models/sharing_models.dart';
import 'package:craftquest_app/features/sharing/data/sharing_repository.dart';
import 'package:craftquest_app/features/teacher/data/teacher_class_repository.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_class_models.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ShareAudience { anyone, group }

class CreateShareCodeSheet extends StatefulWidget {
  const CreateShareCodeSheet({
    super.key,
    required this.quizId,
    required this.isTeacher,
    this.existingShareCode,
  });

  final String quizId;
  final bool isTeacher;
  final ShareCodeModel? existingShareCode;

  static Future<ShareCodeModel?> show(
    BuildContext context, {
    required String quizId,
    required bool isTeacher,
    ShareCodeModel? existingShareCode,
  }) {
    return showModalBottomSheet<ShareCodeModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateShareCodeSheet(
        quizId: quizId,
        isTeacher: isTeacher,
        existingShareCode: existingShareCode,
      ),
    );
  }

  @override
  State<CreateShareCodeSheet> createState() => _CreateShareCodeSheetState();
}

class _CreateShareCodeSheetState extends State<CreateShareCodeSheet> {
  final _sharingRepo = getIt<SharingRepository>();
  final _classRepo = getIt<TeacherClassRepository>();

  ShareAudience _audience = ShareAudience.anyone;
  List<TeacherClassSummaryModel> _classes = [];
  String? _selectedClassId;
  bool _loadingClasses = false;
  bool _creating = false;
  String? _classesError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingShareCode;
    if (existing != null) {
      _audience = existing.accessPolicy == 'group_only'
          ? ShareAudience.group
          : ShareAudience.anyone;
      _selectedClassId = existing.classId;
    }
    if (widget.isTeacher) {
      _loadClasses();
    }
  }

  Future<void> _loadClasses() async {
    setState(() {
      _loadingClasses = true;
      _classesError = null;
    });
    try {
      final classes = await _classRepo.listClasses();
      if (!mounted) return;
      setState(() {
        _classes = classes;
        _selectedClassId ??=
            classes.isNotEmpty ? classes.first.classId : null;
        _loadingClasses = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _classesError = DioErrorMapper.map(e);
        _loadingClasses = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _classesError = DioErrorMapper.genericMessage();
        _loadingClasses = false;
      });
    }
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;

    if (widget.isTeacher &&
        _audience == ShareAudience.group &&
        _selectedClassId == null) {
      context.showErrorSnackBar(l10n.shareCodeGroupRequired);
      return;
    }

    setState(() => _creating = true);
    try {
      final accessPolicy = widget.isTeacher
          ? (_audience == ShareAudience.anyone ? 'guest_open' : 'group_only')
          : null;

      final shareCode = await _sharingRepo.createShareCode(
        quizId: widget.quizId,
        accessPolicy: accessPolicy,
        classId: widget.isTeacher && _audience == ShareAudience.group
            ? _selectedClassId
            : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop(shareCode);
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.shareCodeCreateTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            widget.isTeacher
                ? l10n.shareCodeCreateTeacherSubtitle
                : l10n.shareCodeCreateStudentSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (widget.isTeacher) ...[
            RadioListTile<ShareAudience>(
              value: ShareAudience.anyone,
              groupValue: _audience,
              onChanged: _creating
                  ? null
                  : (v) => setState(() => _audience = v!),
              title: Text(l10n.shareCodeAudienceAnyone),
              subtitle: Text(l10n.shareCodeAudienceAnyoneHint),
            ),
            RadioListTile<ShareAudience>(
              value: ShareAudience.group,
              groupValue: _audience,
              onChanged: _creating
                  ? null
                  : (v) => setState(() => _audience = v!),
              title: Text(l10n.shareCodeAudienceGroup),
              subtitle: Text(l10n.shareCodeAudienceGroupHint),
            ),
            if (_audience == ShareAudience.group) ...[
              if (_loadingClasses)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_classesError != null)
                Text(_classesError!, style: TextStyle(color: Theme.of(context).colorScheme.error))
              else if (_classes.isEmpty)
                Text(l10n.shareCodeNoClasses)
              else
                DropdownButtonFormField<String>(
                  value: _selectedClassId,
                  decoration: InputDecoration(labelText: l10n.shareCodeSelectClassLabel),
                  items: _classes
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.classId,
                          child: Text(
                            l10n.shareCodeClassOption(c.name, c.activeMemberCount),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _creating
                      ? null
                      : (id) => setState(() => _selectedClassId = id),
                ),
              const SizedBox(height: 8),
            ],
          ],
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _creating ? null : _create,
            child: _creating
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.createShareCodeAction),
          ),
        ],
      ),
    );
  }
}

Future<void> showShareCodeResultDialog(
  BuildContext context,
  ShareCodeModel shareCode,
) async {
  final l10n = AppLocalizations.of(context)!;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.shareCodeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            shareCode.code,
            style: Theme.of(ctx).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          if (shareCode.isExisting)
            Text(
              l10n.shareCodeExistingHint,
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          if (shareCode.isExisting) const SizedBox(height: 8),
          Text(
            shareCode.accessPolicy == 'group_only'
                ? l10n.shareCodeResultGroupHint
                : l10n.shareCodeResultOpenHint,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: shareCode.code));
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(l10n.shareCodeCopied)),
            );
          },
          child: Text(l10n.shareCodeCopyAction),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.shareCodeCloseAction),
        ),
      ],
    ),
  );
}
