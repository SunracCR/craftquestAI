import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/quizzes/data/models/quiz_models.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';

class QuizRepository {
  QuizRepository(this._apiClient);

  final ApiClient _apiClient;

  static List<QuestionTypeModel>? _cachedQuestionTypes;
  static DateTime? _questionTypesCachedAt;
  static const _questionTypesTtl = Duration(hours: 1);

  Future<List<QuizModel>> getMyQuizzes() async {
    final response =
        await _apiClient.dio.get<List<dynamic>>('/api/quizzes');
    return (response.data ?? [])
        .map((e) => QuizModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<QuizFolderModel>> getFolders() async {
    final response =
        await _apiClient.dio.get<List<dynamic>>('/api/quiz-folders');
    return (response.data ?? [])
        .map((e) => QuizFolderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<QuizFolderModel> createFolder({
    required String name,
    String? parentFolderId,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/quiz-folders',
      data: {
        'name': name,
        if (parentFolderId != null) 'parentFolderId': parentFolderId,
      },
    );
    return QuizFolderModel.fromJson(response.data!);
  }

  Future<QuizFolderModel> renameFolder({
    required String folderId,
    required String name,
  }) async {
    final response = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/api/quiz-folders/$folderId',
      data: {'name': name},
    );
    return QuizFolderModel.fromJson(response.data!);
  }

  Future<QuizFolderModel> moveFolder({
    required String folderId,
    String? parentFolderId,
    bool clearParent = false,
  }) async {
    final response = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/api/quiz-folders/$folderId',
      data: {
        if (clearParent) 'clearParentFolder': true,
        if (!clearParent && parentFolderId != null)
          'parentFolderId': parentFolderId,
      },
    );
    return QuizFolderModel.fromJson(response.data!);
  }

  Future<void> deleteFolder(String folderId) async {
    await _apiClient.dio.delete<void>('/api/quiz-folders/$folderId');
  }

  Future<QuizModel> moveQuizToFolder({
    required String quizId,
    String? folderId,
    bool clearFolder = false,
  }) async {
    return updateQuiz(
      quizId: quizId,
      folderId: folderId,
      clearFolder: clearFolder,
    );
  }

  Future<QuizModel> getQuiz(String quizId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/quizzes/$quizId',
    );
    return QuizModel.fromJson(response.data!);
  }

  Future<QuizModel> createQuiz({
    required String title,
    String? description,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/quizzes',
      data: {
        'title': title,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    return QuizModel.fromJson(response.data!);
  }

  Future<List<QuestionTypeModel>> getQuestionTypes() async {
    if (_cachedQuestionTypes != null &&
        _questionTypesCachedAt != null &&
        DateTime.now().difference(_questionTypesCachedAt!) < _questionTypesTtl) {
      return _cachedQuestionTypes!;
    }

    final response =
        await _apiClient.dio.get<List<dynamic>>('/api/question-types');
    final types = (response.data ?? [])
        .map((e) => QuestionTypeModel.fromJson(e as Map<String, dynamic>))
        .toList();
    _cachedQuestionTypes = types;
    _questionTypesCachedAt = DateTime.now();
    return types;
  }

  Future<QuestionModel> createQuestion({
    required String quizId,
    required String questionType,
    required String text,
    double points = 1,
    required List<Map<String, dynamic>> answerOptions,
    required List<String> correctAnswerKeys,
    Map<String, dynamic>? justification,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/quizzes/$quizId/questions',
      data: {
        'questionType': questionType,
        'text': text,
        'points': points,
        'answerOptions': answerOptions,
        'correctAnswerKeys': correctAnswerKeys,
        if (justification != null) 'justification': justification,
      },
    );
    return QuestionModel.fromJson(response.data!);
  }

  Future<QuestionModel> updateQuestion({
    required String quizId,
    required String questionId,
    required String questionType,
    required String text,
    double points = 1,
    required List<Map<String, dynamic>> answerOptions,
    required List<String> correctAnswerKeys,
    Map<String, dynamic>? justification,
  }) async {
    final response = await _apiClient.dio.put<Map<String, dynamic>>(
      '/api/quizzes/$quizId/questions/$questionId',
      data: {
        'questionType': questionType,
        'text': text,
        'points': points,
        'answerOptions': answerOptions,
        'correctAnswerKeys': correctAnswerKeys,
        if (justification != null) 'justification': justification,
      },
    );
    return QuestionModel.fromJson(response.data!);
  }

  Future<void> deleteQuestion({
    required String quizId,
    required String questionId,
  }) async {
    await _apiClient.dio.delete<void>(
      '/api/quizzes/$quizId/questions/$questionId',
    );
  }

  Future<List<QuestionModel>> getQuestions(String quizId) async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/api/quizzes/$quizId/questions',
    );
    return (response.data ?? [])
        .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Uint8List> downloadQuizPdf(
    String quizId, {
    required String languageCode,
  }) async {
    final response = await _apiClient.dio.get<List<int>>(
      '/api/quizzes/$quizId/export/pdf',
      queryParameters: {'language': languageCode},
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty PDF response',
      );
    }
    return Uint8List.fromList(data);
  }

  Future<QuizModel> updateQuiz({
    required String quizId,
    String? title,
    String? description,
    bool? randomizeQuestions,
    String? folderId,
    bool clearFolder = false,
  }) async {
    final response = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/api/quizzes/$quizId',
      data: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (randomizeQuestions != null)
          'randomizeQuestions': randomizeQuestions,
        if (clearFolder) 'clearFolder': true,
        if (!clearFolder && folderId != null) 'folderId': folderId,
      },
    );
    return QuizModel.fromJson(response.data!);
  }

  Future<QuizModel> publishQuiz(String quizId) async {
    final response = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/api/quizzes/$quizId',
      data: {'publicationStatus': 'published'},
    );
    return QuizModel.fromJson(response.data!);
  }

  Future<void> deleteQuiz(String quizId) async {
    await _apiClient.dio.delete<void>('/api/quizzes/$quizId');
  }

  String mapError(DioException error) => DioErrorMapper.map(error);
}
