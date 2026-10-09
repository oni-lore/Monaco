import 'package:flutter/material.dart';
import 'package:monaco/screens/login_screen.dart';

void main() => runApp(const MonacoApp());

class MonacoApp extends StatelessWidget {
  const MonacoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Monaco',
    theme: ThemeData(primarySwatch: Colors.indigo),
    darkTheme: ThemeData(primarySwatch: Colors.indigo, brightness: Brightness.dark),
    themeMode: ThemeMode.system,
    home: const LoginScreen(),
    navigatorKey: null,
  );}
