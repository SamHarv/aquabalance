import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'firebase_options.dart';

import 'config/constants.dart';
import 'ui/views/home_view.dart';

// flutter run -d chrome --web-experimental-hot-reload

/// [main] function is entry point of the app
void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const WaterTankInsights());
}

class WaterTankInsights extends StatelessWidget {
  const WaterTankInsights({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appTitle,
      theme: ThemeData(
        fontFamily: GoogleFonts.openSans().fontFamily,
        colorScheme: ColorScheme.fromSeed(seedColor: blue, secondary: black),
        textTheme: GoogleFonts.openSansTextTheme().apply(
          bodyColor: black,
          displayColor: black,
        ),
        scaffoldBackgroundColor: blue,
        appBarTheme: AppBarTheme(
          color: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle(statusBarColor: black),
        ),
      ),
      home: const HomeView(),
    );
  }
}
