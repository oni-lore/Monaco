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
