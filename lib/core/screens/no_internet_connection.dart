import 'package:flutter/material.dart';
import 'dart:io';

import '../app_config.dart';

class NoInternetConnectionScreen extends StatelessWidget {
  const NoInternetConnectionScreen({super.key});

  static Future<bool> checkInternetConnection() async {
    try {
      // print('Check internet');
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      //    print('Check internet error false');
      return false;
    }
  }

  static void showIfNoInternet(BuildContext context) async {
    print('ShowIfNoInternet');
    Navigator.pushAndRemoveUntil(
      context!,
      MaterialPageRoute(
        builder: (context) => const NoInternetConnectionScreen(),
        fullscreenDialog: true,
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: AppConfig.errorScreenDecoration,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 80,
                color: AppConfig.errorScreenIconColor,
              ),
              SizedBox(height: 20),
              Text(
                'Please, check your internet connection and restart',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConfig.errorScreenTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
