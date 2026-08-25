import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final languageCode = ref.watch(languageProvider);
    final router = ref.watch(appRouterProvider);
    
    // Initialize auth state
    ref.watch(authProvider);
    
    return MaterialApp.router(
      title: 'tijariTN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: Locale(languageCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      // Enable RTL for Arabic
      builder: (context, child) {
        final locale = Localizations.localeOf(context);
        final isRTL = locale.languageCode == 'ar';
        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
    );
  }
}
