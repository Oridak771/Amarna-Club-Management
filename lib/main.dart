import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'routes.dart';
import 'theme/app_theme.dart';
import 'services/database_service.dart';
import 'providers/theme_mode_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize French locale data for DateFormat (intl package)
  await initializeDateFormatting('fr_FR');

  final isar = await DatabaseService.init();

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
      ],
      child: const AmarnaClubApp(),
    ),
  );
}

class AmarnaClubApp extends ConsumerWidget {
  const AmarnaClubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Amarna Club',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
