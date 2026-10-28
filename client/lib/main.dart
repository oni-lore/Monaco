import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monaco/providers/auth_provider.dart';
import 'package:monaco/providers/dm_wheel_mode_provider.dart';
import 'package:monaco/screens/auth/login_screen.dart';
import 'package:monaco/screens/auth/registration_screen.dart';
import 'package:monaco/screens/auth/forgot_password_screen.dart';
import 'package:monaco/screens/home_screen.dart';
import 'package:monaco/screens/search_screen.dart';
import 'package:monaco/screens/profile_screen.dart';
import 'package:monaco/screens/loading_chambers_screen.dart';
import 'package:monaco/utils/design_system.dart';
import 'package:monaco/widgets/monaco_loader.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MonacoApp());
}

ThemeData _monoThemeData({required Brightness brightness}) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MonacoDesign.inkBlack,
      brightness: brightness,
    ),
    scaffoldBackgroundColor: MonacoDesign.charcoalDeep,
    appBarTheme: const AppBarTheme(
      backgroundColor: MonacoDesign.charcoalDeep,
      elevation: 0,
      iconTheme: IconThemeData(color: MonacoDesign.accentBright),
      titleTextStyle: TextStyle(
        color: MonacoDesign.accentBright,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
    ),
    bottomAppBarTheme: const BottomAppBarTheme(
      elevation: 1,
    ),
    cardTheme: CardTheme(
      color: MonacoDesign.charcoalCard,
      elevation: 0,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: MonacoDesign.charcoalSurface,
      selectedItemColor: MonacoDesign.accentBright,
      unselectedItemColor: MonacoDesign.textMuted,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: MonacoDesign.textBody),
      bodySmall: TextStyle(color: MonacoDesign.textSecondary),
      labelMedium: TextStyle(color: MonacoDesign.textMuted),
      titleLarge: TextStyle(
        color: MonacoDesign.textInk,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MonacoDesign.charcoalSurface,
      hintStyle: TextStyle(
        color: MonacoDesign.textMuted.withOpacity(0.7),
        fontSize: 14,
      ),
      labelStyle: TextStyle(
        color: MonacoDesign.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MonacoDesign.radiusMd),
        borderSide: BorderSide(color: MonacoDesign.borderMuted, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MonacoDesign.radiusMd),
        borderSide: BorderSide(color: MonacoDesign.borderMuted, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MonacoDesign.radiusMd),
        borderSide: BorderSide(color: MonacoDesign.inkBlack, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MonacoDesign.radiusMd),
        borderSide: BorderSide(color: MonacoDesign.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MonacoDesign.radiusMd),
        borderSide: BorderSide(color: MonacoDesign.error, width: 2),
      ),
    ),
    iconTheme: const IconThemeData(color: MonacoDesign.accentBright),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: MonacoDesign.accentBright,
        backgroundColor: Colors.transparent,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: MonacoDesign.charcoalCard,
        foregroundColor: MonacoDesign.accentBright,
        elevation: 0,
      ),
    ),
  );
}

class MonacoApp extends StatelessWidget {
  const MonacoApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (BuildContext _) => AuthProvider()),
      ChangeNotifierProvider(create: (BuildContext _) => DMWheelModeProvider()),
    ],
    child: MaterialApp(
      title: 'Monaco',
      debugShowCheckedModeBanner: false,
      theme: _monoThemeData(brightness: Brightness.light),
      darkTheme: _monoThemeData(brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegistrationScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
      '/home': (_) => const HomeScreen(),
      '/loading-chambers': (_) => const LoadingChambersScreen(),
      '/search': (_) => const SearchScreen(),
      '/profile': (_) => const ProfileScreen(),
      },
    ),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => Consumer<AuthProvider>(
    builder: (BuildContext context, AuthProvider auth, Widget? _) {
      if (!auth.isInitialized) {
        debugPrint('AuthGate: showing MonacoLoader (isInitialized=false)');
        return const MonacoLoader();
      }
      if (auth.isAuthenticated) {
        debugPrint('AuthGate: showing HomeScreen (isAuthenticated=true)');
        return const HomeScreen();
      }
      debugPrint('AuthGate: showing LoginScreen (isInitialized=true, isAuthenticated=false)');
      return const LoginScreen();
    },
  );
}
