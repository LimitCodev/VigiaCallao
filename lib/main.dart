import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  runApp(const VigiaCallaoApp());
}

class VigiaCallaoApp extends StatelessWidget {
  const VigiaCallaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VigíaCallao',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const LoginScreen(),
    );
  }
}
