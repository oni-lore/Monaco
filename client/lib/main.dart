import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:monaco/providers/auth_provider.dart';
import 'package:monaco/providers/dm_wheel_mode_provider.dart';
import 'package:monaco/screens/auth/login_screen.dart';
import 'package:monaco/screens/auth/registration_screen.dart';
import 'package:monaco/screens/auth/forgot_password_screen.dart';
import 'package:monaco/screens/auth/reset_password_screen.dart';
import 'package:monaco/screens/home_screen.dart';
import 'package:monaco/screens/conversation_screen.dart';
import 'package:monaco/screens/search_screen.dart';
import 'package:monaco/screens/profile_screen.dart';
import 'package:monaco/screens/loading_chambers_screen.dart';
import 'package:monaco/widgets/monaco_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(const MonacoApp());
}

/// Provides persisted DM Quick-Access wheel mode (Left / Right / Off).
/// Defined in lib/providers/dm_wheel_mode_provider.dart.

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
        '/reset-password': (_) => const ResetPasswordScreen(),
        '/home': (_) => const HomeScreen(),
        '/loading-chambers': (_) => const LoadingChambersScreen(),
        '/search': (_) => const SearchScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/conversation') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => ConversationScreen(
              conversationId: args['conversationId'] as String,
              conversationTitle: args['conversationTitle'] as String,
            ),
          );
        }
        if (settings.name == '/reset-password') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              token: args['token'] as String,
            ),
          );
        }
        return null;
      },
    ),
  );
}

ThemeData _monoThemeData({required Brightness brightness}) {
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: MonacoDesign.inkBlack,
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: MonacoDesign.charcoalDeep,
    scaffoldBodyColor: MonacoDesign.charcoalDeep,
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
      color: MonacoDesign.charcoalSurface,
      elevation: 1,
    ),
    cardTheme: CardTheme(
      color: MonacoDesign.charcoalCard,
      borderRadius: BorderRadius.circular(MonacoDesign.radiusLg),
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
        foregroundColor: MonacoDesign.inkBlack,
        backgroundColor: Colors.transparent,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: MonacoDesign.inkBlack,
        foregroundColor: MonacoDesign.accentBright,
        elevation: 0,
      ),
    ),
  );
}
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegistrationScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/home': (_) => const HomeScreen(),
        '/loading-chambers': (_) => const LoadingChambersScreen(),
        '/search': (_) => const SearchScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/conversation') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => ConversationScreen(
              conversationId: args['conversationId'] as String,
              conversationTitle: args['conversationTitle'] as String,
            ),
          );
        }
        if (settings.name == '/reset-password') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              token: args['token'] as String,
            ),
          );
        }
        return null;
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
        return const MonacoLoader();
      }
      if (auth.isAuthenticated) {
        return const HomeScreen();
      }
      return const LoginScreen();
    },
  );
}
