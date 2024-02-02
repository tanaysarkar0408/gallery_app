import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:gallery_app/theme_provider.dart';
import 'package:provider/provider.dart';
import 'homepage.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Provider.of<ThemeProvider>(context).currentTheme,
      home: AnimatedSplashScreen(
        curve: Curves.easeIn,
        duration: 3500,
        animationDuration: Duration(seconds: 2),
        splashIconSize: 500,
        splash: Image.asset('assets/logo.png'),
        nextScreen: HomePage(),
        splashTransition: SplashTransition.scaleTransition,
      ),
    );
  }
}
