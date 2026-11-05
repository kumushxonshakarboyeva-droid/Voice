import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'home_screen.dart';
import 'app_controller.dart';

class VoiceLifeApp extends StatelessWidget {
  const VoiceLifeApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final themeMode = switch (controller.settings.themeMode) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
        return MaterialApp(
          title: 'VOICE LIFE',
          debugShowCheckedModeBanner: false,
          locale: Locale(controller.settings.uiLanguage),
          supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          themeMode: themeMode,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: HomeScreen(controller: controller),
        );
      },
    );
  }

  ThemeData _theme(Brightness brightness) {
    const seed = Color(0xFF7357D8);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: brightness == Brightness.light
          ? const Color(0xFFF8F6FC)
          : const Color(0xFF15131C),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'Roboto',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? const Color(0xFFF4F0FA)
            : const Color(0xFF292635),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: seed, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: .14),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : null,
          ),
        ),
      ),
    );
  }
}
