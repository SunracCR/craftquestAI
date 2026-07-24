import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Directorio base para DB offline y archivos de media (sin depender de path_provider).
Future<String> offlineStorageRootPath() async {
  final root = await getDatabasesPath();
  return p.join(root, 'offline_practice');
}

Future<String> offlineMediaDirectoryPath(String quizId) async {
  return p.join(await offlineStorageRootPath(), 'media', quizId);
}

Future<String> offlineDatabaseFilePath() async {
  return p.join(await offlineStorageRootPath(), 'offline_practice.db');
}
