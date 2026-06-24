import 'package:craftquest_app/features/quizzes/data/models/quiz_models.dart';

class QuizFolderNode {
  const QuizFolderNode({
    required this.folder,
    required this.children,
    required this.quizzes,
  });

  final QuizFolderModel folder;
  final List<QuizFolderNode> children;
  final List<QuizModel> quizzes;
}

List<QuizFolderNode> buildQuizFolderTree({
  required List<QuizFolderModel> folders,
  required List<QuizModel> quizzes,
  String? parentFolderId,
}) {
  final childFolders = folders
      .where((folder) => folder.parentFolderId == parentFolderId)
      .toList()
    ..sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      if (order != 0) return order;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

  return childFolders
      .map(
        (folder) => QuizFolderNode(
          folder: folder,
          children: buildQuizFolderTree(
            folders: folders,
            quizzes: quizzes,
            parentFolderId: folder.quizFolderId,
          ),
          quizzes: quizzes
              .where((quiz) => quiz.folderId == folder.quizFolderId)
              .toList(),
        ),
      )
      .toList();
}

List<QuizModel> uncategorizedQuizzes(List<QuizModel> quizzes) =>
    quizzes.where((quiz) => quiz.folderId == null).toList();

int countQuizzesInFolderSubtree(QuizFolderNode node) {
  var count = node.quizzes.length;
  for (final child in node.children) {
    count += countQuizzesInFolderSubtree(child);
  }
  return count;
}

List<QuizFolderModel> flattenFolderTree(List<QuizFolderNode> nodes) {
  final result = <QuizFolderModel>[];
  for (final node in nodes) {
    result.add(node.folder);
    result.addAll(flattenFolderTree(node.children));
  }
  return result;
}

bool isFolderDescendantOf({
  required List<QuizFolderModel> folders,
  required String folderId,
  required String potentialAncestorId,
}) {
  var current = folders.where((f) => f.quizFolderId == folderId).firstOrNull;
  while (current != null) {
    if (current.parentFolderId == potentialAncestorId) {
      return true;
    }
    final parentId = current.parentFolderId;
    if (parentId == null) {
      return false;
    }
    current = folders.where((f) => f.quizFolderId == parentId).firstOrNull;
  }
  return false;
}
