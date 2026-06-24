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

sealed class QuizDragData {
  const QuizDragData();
}

class QuizFolderDrag extends QuizDragData {
  const QuizFolderDrag(this.folder);

  final QuizFolderModel folder;
}

class QuizItemDrag extends QuizDragData {
  const QuizItemDrag(this.quiz);

  final QuizModel quiz;
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
  if (folderId == potentialAncestorId) {
    return true;
  }

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

int folderSubtreeHeight({
  required List<QuizFolderModel> folders,
  required String folderId,
}) {
  final children = folders
      .where((folder) => folder.parentFolderId == folderId)
      .toList();
  if (children.isEmpty) {
    return 0;
  }

  var maxChildHeight = 0;
  for (final child in children) {
    final childHeight = folderSubtreeHeight(
      folders: folders,
      folderId: child.quizFolderId,
    );
    if (childHeight > maxChildHeight) {
      maxChildHeight = childHeight;
    }
  }
  return 1 + maxChildHeight;
}

bool canDropFolderInto({
  required List<QuizFolderModel> folders,
  required String dragFolderId,
  String? targetFolderId,
}) {
  if (targetFolderId == null) {
    return true;
  }

  if (dragFolderId == targetFolderId) {
    return false;
  }

  if (isFolderDescendantOf(
    folders: folders,
    folderId: targetFolderId,
    potentialAncestorId: dragFolderId,
  )) {
    return false;
  }

  final target = folders
      .where((folder) => folder.quizFolderId == targetFolderId)
      .firstOrNull;
  if (target == null) {
    return false;
  }

  final subtreeHeight = folderSubtreeHeight(
    folders: folders,
    folderId: dragFolderId,
  );
  return target.depth + 1 + subtreeHeight <= 2;
}

bool canDropQuizInto({
  required QuizModel quiz,
  String? targetFolderId,
}) {
  if (targetFolderId == null) {
    return quiz.folderId != null;
  }
  return quiz.folderId != targetFolderId;
}

String folderPathLabel({
  required List<QuizFolderModel> folders,
  required String? folderId,
  required String uncategorizedLabel,
}) {
  if (folderId == null) {
    return uncategorizedLabel;
  }

  final segments = <String>[];
  String? currentId = folderId;
  while (currentId != null) {
    final folder =
        folders.where((item) => item.quizFolderId == currentId).firstOrNull;
    if (folder == null) {
      break;
    }
    segments.insert(0, folder.name);
    currentId = folder.parentFolderId;
  }

  return segments.isEmpty ? uncategorizedLabel : segments.join(' / ');
}

List<QuizModel> filterQuizzesBySearch({
  required List<QuizModel> quizzes,
  required String query,
}) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return quizzes;
  }

  return quizzes.where((quiz) {
    final title = quiz.title.toLowerCase();
    final description = quiz.description?.toLowerCase() ?? '';
    return title.contains(normalized) || description.contains(normalized);
  }).toList();
}
