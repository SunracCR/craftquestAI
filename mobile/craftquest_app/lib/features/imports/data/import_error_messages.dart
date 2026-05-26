import 'package:craftquest_app/core/utils/question_image_types.dart';
import 'package:craftquest_app/features/imports/data/models/import_models.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';

abstract final class ImportErrorMessages {
  static String localize(ImportErrorModel error, AppLocalizations l10n) {
    return switch (error.errorCode) {
      'IMAGE_MEDIA_PENDING' => l10n.importImageMediaPending,
      'MEDIA_NOT_SUPPORTED_YET' => l10n.importImageMediaPending,
      _ => error.message,
    };
  }

  static bool isImageType(String questionType) =>
      QuestionImageTypes.isImageType(questionType);
}
