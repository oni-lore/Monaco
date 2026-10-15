import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:monaco/providers/auth_provider.dart';
import 'package:monaco/screens/auth/login_screen.dart';
import 'package:monaco/screens/auth/registration_screen.dart';
import 'package:monaco/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(const MonacoApp());
}

class MonacoApp extends StatelessWidget {
  const MonacoApp({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (BuildContext _) => AuthProvider(),
    child: MaterialApp(
      title: 'Monaco',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegistrationScreen(),
        '/home': (_) => const HomeScreen(),
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
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      if (auth.isAuthenticated) {
        return const HomeScreen();
      }
      return const LoginScreen();
    },
  );
}
