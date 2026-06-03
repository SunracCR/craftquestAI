import 'package:flutter/material.dart';

/// Mensajero raíz para snackbars con scaffolds anidados (shell + páginas).
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Navigator raíz (home + rutas push desde guest/login/registro).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
