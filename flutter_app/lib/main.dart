import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'screens/home_shell.dart';
import 'screens/splash_screen.dart';

final themeModeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RabbitHubApp());
}

class RabbitHubApp extends StatelessWidget {
  const RabbitHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) => MaterialApp(
        title: 'Rabbit Hub',
        debugShowCheckedModeBanner: false,
        theme: rabbitTheme(Brightness.light),
        darkTheme: rabbitTheme(Brightness.dark),
        themeMode: mode,
        home: const _AppLaunchGate(),
      ),
    );
  }
}

class _AppLaunchGate extends StatefulWidget {
  const _AppLaunchGate();

  @override
  State<_AppLaunchGate> createState() => _AppLaunchGateState();
}

class _AppLaunchGateState extends State<_AppLaunchGate> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 420),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    child: _showSplash
        ? SplashScreen(
            key: const ValueKey('splash'),
            onFinished: () => setState(() => _showSplash = false),
          )
        : const HomeShell(key: ValueKey('home')),
  );
}
