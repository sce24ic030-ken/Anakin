import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: '.env');
  
  await [
    Permission.camera,
    Permission.storage,
  ].request();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const AnakinWebOracleApp());
}

class AnakinWebOracleApp extends StatefulWidget {
  const AnakinWebOracleApp({super.key});

  @override
  State<AnakinWebOracleApp> createState() => _AnakinWebOracleAppState();
}

class _AnakinWebOracleAppState extends State<AnakinWebOracleApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  String _language = 'en';
  bool _initialized = false;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _changeLanguage(String lang) {
    setState(() {
      _language = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anakin',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: _initialized
          ? MainScreen(
              themeMode: _themeMode,
              onToggleTheme: _toggleTheme,
              language: _language,
              onChangeLanguage: _changeLanguage,
            )
          : SplashScreen(
              onInitializationComplete: () => setState(() => _initialized = true),
            ),
    );
  }
}