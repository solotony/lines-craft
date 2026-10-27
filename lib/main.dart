import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/ui/game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LinesApp());
}

class LinesApp extends StatelessWidget {
  const LinesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Lines',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: false,
      ),
      home: const Scaffold(
        body: Shortcuts(
          shortcuts: <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
          },
          child: GameScreen(),
        ),
      ),
    );
  }
}
