import 'package:flutter/material.dart';
import 'package:qBitRemote/widgets/qbitremote.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'qBittorrent Remote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'RobotoMono',
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Colors.orange,
          onPrimary: Colors.blue,
          secondary: Colors.purple,
          onSecondary: Colors.deepPurple,
          error: Colors.red,
          onError: Colors.orange,
          background: Colors.black,
          onBackground: Colors.black,
          surface: Colors.black,
          onSurface: Colors.black,
        ),
        cardColor: Theme.of(context).primaryColor,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const QBitRemote(),
    );
  }
}
