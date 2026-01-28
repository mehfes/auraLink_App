import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'theme.dart';
import 'providers/app_state.dart';
import 'screens/main_screen.dart';

// ---------------------------------------------------------------------------
// AURALINK OS - MAIN ENTRY POINT
// ---------------------------------------------------------------------------
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const AuraLinkApp(),
    ),
  );
}

class AuraLinkApp extends StatelessWidget {
  const AuraLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to AppState for theme changes
    final state = Provider.of<AppState>(context);
    
    return MaterialApp(
      title: 'AuraLink OS',
      debugShowCheckedModeBanner: false,
      themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppTheme.primaryColor,
        scaffoldBackgroundColor: AppTheme.backgroundColor,
        textTheme: GoogleFonts.sairaTextTheme(),
        colorScheme: ColorScheme.fromSwatch(brightness: Brightness.light).copyWith(
          primary: AppTheme.primaryColor,
          secondary: AppTheme.primaryColor,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppTheme.primaryColor,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E), // Explicit card color
        canvasColor: const Color(0xFF1E1E1E), 
        textTheme: GoogleFonts.sairaTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
          primary: AppTheme.primaryColor, // Keep blue accent
          background: const Color(0xFF121212),
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
