import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Arranca la carga inicial tras el primer frame (ruta ya montada).
void scheduleInitialScreenLoad(VoidCallback load) {
  SchedulerBinding.instance.scheduleFrameCallback((_) {
    load();
  });
}

/// Refresca la pantalla padre tras volver de una ruta hija, sin bloquear el pop.
void scheduleReturnRefresh(VoidCallback refresh) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    refresh();
  });
}

/// Ignora resultados de cargas concurrentes obsoletas.
mixin ScreenLoadGeneration {
  int _screenLoadGeneration = 0;

  int beginScreenLoad() => ++_screenLoadGeneration;

  bool isStaleScreenLoad(int loadId) => loadId != _screenLoadGeneration;
}
