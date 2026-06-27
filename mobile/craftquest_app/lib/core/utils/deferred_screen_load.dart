import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Arranca la carga inicial tras el primer frame (ruta ya montada).
void scheduleInitialScreenLoad(VoidCallback load) {
  SchedulerBinding.instance.scheduleFrameCallback((_) {
    load();
  });
}

/// Ignora resultados de cargas concurrentes obsoletas.
mixin ScreenLoadGeneration {
  int _screenLoadGeneration = 0;

  int beginScreenLoad() => ++_screenLoadGeneration;

  bool isStaleScreenLoad(int loadId) => loadId != _screenLoadGeneration;
}
