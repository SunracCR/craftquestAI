/// Question types that support images attached later in the app.
abstract final class QuestionImageTypes {
  static const imageChoice = 'image_choice';
  static const imageBased = 'image_based_question';

  static bool isImageType(String type) =>
      type == imageChoice || type == imageBased;
}
