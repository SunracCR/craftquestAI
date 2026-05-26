import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/utils/question_type_labels.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/core/widgets/option_image_picker.dart';
import 'package:craftquest_app/features/quizzes/data/models/quiz_models.dart';
import 'package:craftquest_app/features/quizzes/data/quiz_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class AddQuestionPage extends StatefulWidget {
  const AddQuestionPage({
    super.key,
    required this.quizId,
    this.existingQuestion,
  });

  final String quizId;
  final QuestionModel? existingQuestion;

  bool get isEditing => existingQuestion != null;

  @override
  State<AddQuestionPage> createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends State<AddQuestionPage> {
  final _repository = getIt<QuizRepository>();
  final _textController = TextEditingController();
  final _pointsController = TextEditingController(text: '1');
  final _optionA = TextEditingController();
  final _optionB = TextEditingController();
  final _optionC = TextEditingController();
  final _optionD = TextEditingController();

  List<QuestionTypeModel>? _types;
  String _selectedType = 'single_choice';
  String _correctKey = 'A';
  final Set<String> _correctKeys = {'A'};
  String? _questionMediaId;
  bool _loading = false;
  final Map<String, String?> _optionMediaIds = {
    'A': null,
    'B': null,
    'C': null,
    'D': null,
  };

  QuestionTypeModel? get _selectedTypeModel {
    final types = _types;
    if (types == null) return null;
    for (final type in types) {
      if (type.code == _selectedType) return type;
    }
    return null;
  }

  bool get _isTrueFalse => _selectedType == 'true_false';
  bool get _isMultipleChoice =>
      _selectedTypeModel?.supportsMultipleCorrectAnswers ?? false;
  bool get _showQuestionImage => _selectedType == 'image_based_question';
  bool get _showOptionImages =>
      _selectedType == 'image_choice' || _selectedType == 'image_based_question';

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  void _applyExistingQuestion(QuestionModel question) {
    _textController.text = question.text;
    _pointsController.text = _formatPoints(question.points);
    _selectedType = question.questionType;
    final correctIds = question.correctAnswerOptionIds.toSet();
    for (final option in question.answerOptions) {
      final key = option.stableKey.toUpperCase();
      if (key.isQuestionStemOption) {
        _questionMediaId = option.mediaAssetId;
        continue;
      }

      if (key == 'TRUE' || key == 'FALSE') {
        if (correctIds.contains(option.answerOptionId)) {
          _correctKey = key;
          _correctKeys
            ..clear()
            ..add(key);
        }
        continue;
      }

      final controller = _controllerForKey(key);
      controller.text = option.text?.trim() ?? '';
      _optionMediaIds[key] = option.mediaAssetId;

      if (correctIds.contains(option.answerOptionId)) {
        if (_isMultipleChoice) {
          _correctKeys.add(key);
        } else {
          _correctKey = key;
        }
      }
    }
  }

  Future<void> _loadTypes() async {
    try {
      final types = await _repository.getQuestionTypes();
      if (!mounted) return;
      setState(() {
        _types = types;
        final existing = widget.existingQuestion;
        if (existing != null) {
          _applyExistingQuestion(existing);
        } else if (types.isNotEmpty) {
          _selectedType = types.first.code;
          _resetCorrectSelection();
        }
      });
    } catch (_) {}
  }

  void _resetCorrectSelection() {
    if (_isTrueFalse) {
      _correctKey = 'TRUE';
      _correctKeys
        ..clear()
        ..add('TRUE');
    } else if (_isMultipleChoice) {
      _correctKey = 'A';
      _correctKeys
        ..clear()
        ..add('A');
    } else {
      _correctKey = 'A';
      _correctKeys
        ..clear()
        ..add('A');
    }
  }

  String _formatPoints(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  double? _parsePoints() {
    final raw = _pointsController.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  @override
  void dispose() {
    _textController.dispose();
    _pointsController.dispose();
    _optionA.dispose();
    _optionB.dispose();
    _optionC.dispose();
    _optionD.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_textController.text.trim().isEmpty) {
      context.showErrorSnackBar(l10n.fieldRequired);
      return;
    }

    final points = _parsePoints();
    if (points == null || points <= 0) {
      context.showErrorSnackBar(l10n.questionInvalidPoints);
      return;
    }

    if (_showQuestionImage &&
        (_questionMediaId == null || _questionMediaId!.isEmpty)) {
      context.showErrorSnackBar(l10n.requireQuestionImage);
      return;
    }

    final options = <Map<String, dynamic>>[];

    if (_showQuestionImage) {
      options.add({
        'clientKey': kQuestionImageOptionKey,
        'text': ' ',
        'defaultSortOrder': -1,
        'mediaAssetId': _questionMediaId,
      });
    }

    void addOption(String key, TextEditingController controller, int order) {
      if (controller.text.trim().isNotEmpty) {
        final option = <String, dynamic>{
          'clientKey': key,
          'text': controller.text.trim(),
          'defaultSortOrder': order,
        };
        final mediaId = _optionMediaIds[key];
        if (mediaId != null && mediaId.isNotEmpty) {
          option['mediaAssetId'] = mediaId;
        }
        options.add(option);
      }
    }

    if (_isTrueFalse) {
      options
        ..add({'clientKey': 'TRUE', 'text': l10n.trueLabel, 'defaultSortOrder': 0})
        ..add({'clientKey': 'FALSE', 'text': l10n.falseLabel, 'defaultSortOrder': 1});
    } else {
      addOption('A', _optionA, 0);
      addOption('B', _optionB, 1);
      addOption('C', _optionC, 2);
      addOption('D', _optionD, 3);
    }

    final selectableCount = options
        .where((o) => o['clientKey'] != kQuestionImageOptionKey)
        .length;
    if (selectableCount < 2) {
      context.showErrorSnackBar(l10n.minTwoOptions);
      return;
    }

    if (_selectedType == 'image_choice') {
      final answerOptions = options.where(
        (o) => o['clientKey'] != kQuestionImageOptionKey,
      );
      final hasImage = answerOptions.any((o) => o['mediaAssetId'] != null);
      if (!hasImage) {
        context.showErrorSnackBar(l10n.requireOptionImage);
        return;
      }
    }

    final correctKeys = _isTrueFalse
        ? [_correctKey == 'TRUE' ? 'TRUE' : 'FALSE']
        : _isMultipleChoice
            ? _correctKeys.toList()
            : [_correctKey];

    if (correctKeys.isEmpty) {
      context.showErrorSnackBar(l10n.selectAtLeastOneCorrect);
      return;
    }

    setState(() => _loading = true);
    try {
      final existing = widget.existingQuestion;
      if (existing != null) {
        await _repository.updateQuestion(
          quizId: widget.quizId,
          questionId: existing.questionId,
          questionType: _selectedType,
          text: _textController.text.trim(),
          points: points,
          answerOptions: options,
          correctAnswerKeys: correctKeys,
        );
      } else {
        await _repository.createQuestion(
          quizId: widget.quizId,
          questionType: _selectedType,
          text: _textController.text.trim(),
          points: points,
          answerOptions: options,
          correctAnswerKeys: correctKeys,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _typeHint(AppLocalizations l10n) {
    final text = switch (_selectedType) {
      'image_choice' => l10n.imageChoiceHint,
      'image_based_question' => l10n.imageBasedQuestionHint,
      'multiple_choice' => l10n.selectCorrectAnswersHint,
      _ => null,
    };
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }

  Widget _buildCorrectSelection(AppLocalizations l10n) {
    if (_isTrueFalse) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.correctAnswerKeyLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.trueLabel),
                selected: _correctKey == 'TRUE',
                onSelected: (_) => setState(() => _correctKey = 'TRUE'),
              ),
              ChoiceChip(
                label: Text(l10n.falseLabel),
                selected: _correctKey == 'FALSE',
                onSelected: (_) => setState(() => _correctKey = 'FALSE'),
              ),
            ],
          ),
        ],
      );
    }

    if (_isMultipleChoice) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.correctAnswersLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['A', 'B', 'C', 'D'].map((key) {
              final selectable = _optionIsSelectable(key);
              return FilterChip(
                label: Text(key),
                selected: _correctKeys.contains(key),
                onSelected: selectable
                    ? (selected) {
                        setState(() {
                          if (selected) {
                            _correctKeys.add(key);
                          } else {
                            _correctKeys.remove(key);
                          }
                        });
                      }
                    : null,
              );
            }).toList(),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.correctAnswerKeyLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['A', 'B', 'C', 'D'].map((key) {
            final selectable = _optionIsSelectable(key);
            return ChoiceChip(
              label: Text(key),
              selected: _correctKey == key,
              onSelected: selectable
                  ? (_) => setState(() => _correctKey = key)
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  TextEditingController _controllerForKey(String key) => switch (key) {
        'A' => _optionA,
        'B' => _optionB,
        'C' => _optionC,
        'D' => _optionD,
        _ => _optionA,
      };

  /// Opción utilizable para marcar respuesta correcta (texto o imagen adjunta).
  bool _optionIsSelectable(String key) {
    if (_isTrueFalse) return true;
    if (_controllerForKey(key).text.trim().isNotEmpty) return true;
    if (_showOptionImages) {
      final mediaId = _optionMediaIds[key];
      return mediaId != null && mediaId.isNotEmpty;
    }
    return false;
  }

  void _onOptionContentChanged(String key) {
    setState(() {
      if (!_optionIsSelectable(key)) {
        _correctKeys.remove(key);
        if (_correctKey == key) {
          _correctKey = _firstSelectableOptionKey() ?? 'A';
        }
      }
    });
  }

  String? _firstSelectableOptionKey() {
    for (final key in ['A', 'B', 'C', 'D']) {
      if (_optionIsSelectable(key)) return key;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(
        title: widget.isEditing ? l10n.editQuestionTitle : l10n.addQuestionTitle,
      ),
      bottomBar: AppBottomActionBar(
        children: [
          AppGradientPrimaryButton(
            label: l10n.saveQuestionAction,
            isLoading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.pageVertical,
        children: [
          if (_types != null)
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: InputDecoration(labelText: l10n.questionTypeLabel),
              items: _types!
                  .map(
                    (t) => DropdownMenuItem(
                      value: t.code,
                      child: Text(t.code.displayLabel(l10n)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null && v != _selectedType) {
                  setState(() {
                    _selectedType = v;
                    _questionMediaId = null;
                    _resetCorrectSelection();
                  });
                }
              },
            ),
          _typeHint(l10n),
          const SizedBox(height: 16),
          TextField(
            controller: _pointsController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.questionPointsLabel,
              hintText: l10n.questionPointsHint,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            maxLines: 3,
            decoration: InputDecoration(labelText: l10n.questionTextLabel),
          ),
          if (_showQuestionImage) ...[
            const SizedBox(height: 16),
            OptionImagePicker(
              label: l10n.questionImageLabel,
              mediaAssetId: _questionMediaId,
              onChanged: (id) => setState(() => _questionMediaId = id),
            ),
          ],
          if (!_isTrueFalse) ...[
            const SizedBox(height: 16),
            _optionField('A', _optionA, l10n),
            _optionField('B', _optionB, l10n),
            _optionField('C', _optionC, l10n),
            _optionField('D', _optionD, l10n),
          ],
          const SizedBox(height: 8),
          _buildCorrectSelection(l10n),
        ],
      ),
    );
  }

  Widget _optionField(String key, TextEditingController controller, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            onChanged: (_) => _onOptionContentChanged(key),
            decoration: InputDecoration(labelText: l10n.answerOptionLabel(key)),
          ),
          if (_showOptionImages) ...[
            const SizedBox(height: 4),
            OptionImagePicker(
              label: l10n.answerOptionLabel(key),
              mediaAssetId: _optionMediaIds[key],
              onChanged: (id) {
                _optionMediaIds[key] = id;
                _onOptionContentChanged(key);
              },
            ),
          ],
        ],
      ),
    );
  }
}
