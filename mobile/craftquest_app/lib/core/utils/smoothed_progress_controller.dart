import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Smooths server-reported AI job progress for display.
class SmoothedProgressController extends ChangeNotifier {
  SmoothedProgressController({
    this.stallThreshold = const Duration(seconds: 3),
    this.stallCeilingOffset = 12,
    this.maxGeneratingDisplay = 68,
  });

  final Duration stallThreshold;
  final int stallCeilingOffset;
  final int maxGeneratingDisplay;

  int _serverPercent = 0;
  double _displayPercent = 0;
  DateTime? _lastServerChange;
  String? _stage;
  Timer? _timer;
  bool _isActive = false;

  int get serverPercent => _serverPercent;
  int get displayPercent => _displayPercent.round().clamp(0, 100);
  double get displayPercentExact => _displayPercent.clamp(0, 100);
  bool get isStalled =>
      _isActive &&
      _lastServerChange != null &&
      DateTime.now().difference(_lastServerChange!) > stallThreshold;

  void updateFromServer({
    required int? progressPercent,
    required String? stage,
    required bool isActiveGeneration,
  }) {
    _stage = stage;
    _isActive = isActiveGeneration;

    if (progressPercent != null && progressPercent > _serverPercent) {
      _serverPercent = progressPercent;
      _lastServerChange = DateTime.now();
    } else if (stage != null && _lastServerChange == null) {
      _lastServerChange = DateTime.now();
    }

    _ensureTimer(isActiveGeneration);
    _tick();
    notifyListeners();
  }

  void reset() {
    _serverPercent = 0;
    _displayPercent = 0;
    _lastServerChange = null;
    _stage = null;
    _isActive = false;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void disposeController() {
    _timer?.cancel();
    _timer = null;
  }

  void _ensureTimer(bool active) {
    if (!active) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(const Duration(milliseconds: 120), (_) => _tick());
  }

  void _tick() {
    final target = _serverPercent.toDouble();
    var next = _displayPercent;

    if (next < target) {
      next = math.min(next + 1.8, target);
    } else if (_isActive &&
        _stage == 'generating' &&
        _lastServerChange != null &&
        DateTime.now().difference(_lastServerChange!) > stallThreshold) {
      final ceiling = math.min(
        _serverPercent + stallCeilingOffset,
        maxGeneratingDisplay,
      ).toDouble();
      if (next < ceiling) {
        next += 0.18;
      }
    }

    final rounded = next.clamp(0.0, 100.0);
    if ((rounded - _displayPercent).abs() > 0.01) {
      _displayPercent = rounded;
      notifyListeners();
    }
  }
}

/// Estimated progress while polling study-material analysis (no server %).
class EstimatedAnalysisProgressController extends ChangeNotifier {
  EstimatedAnalysisProgressController();

  static const _milestones = [12, 35, 58, 78];

  Timer? _timer;
  int _index = 0;
  double _display = 0;
  bool _running = false;

  int get displayPercent => _display.round().clamp(0, 92);

  void start() {
    if (_running) return;
    _running = true;
    _index = 0;
    _display = _milestones.first.toDouble();
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _advance());
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  void disposeController() => stop();

  void _advance() {
    if (_index >= _milestones.length - 1) {
      _display = math.min(_display + 0.4, 92);
    } else {
      _index++;
      _display = _milestones[_index].toDouble();
    }
    notifyListeners();
  }
}

/// Byte upload progress 0.0–1.0 for multipart uploads.
class UploadProgressNotifier extends ValueNotifier<double?> {
  UploadProgressNotifier() : super(null);

  void reset() => value = null;

  void report(int sent, int total) {
    if (total <= 0) return;
    value = (sent / total).clamp(0, 1);
  }
}
