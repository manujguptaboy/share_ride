import 'package:flutter/material.dart';
import 'package:share_ride/core/constants/app_strings.dart';
import 'package:share_ride/core/theme/app_theme.dart';
import 'package:share_ride/features/auth/presentation/pages/login_page.dart';

class ShareRideApp extends StatelessWidget {
  const ShareRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
    );
  }
}
