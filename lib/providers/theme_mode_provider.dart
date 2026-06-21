import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls the active [ThemeMode] across the app.
/// Default is [ThemeMode.system] so the app follows the OS setting.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
