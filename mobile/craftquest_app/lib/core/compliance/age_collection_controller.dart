import 'package:craftquest_app/core/compliance/age_collection_storage.dart';
import 'package:flutter/foundation.dart';

/// Notifica a [AgeCollectionGate] cuando hay que volver a pedir la fecha.
class AgeCollectionController extends ChangeNotifier {
  AgeCollectionController(this._storage);

  final AgeCollectionStorage _storage;

  Future<void> requestRecollection() async {
    await _storage.clear();
    notifyListeners();
  }
}
