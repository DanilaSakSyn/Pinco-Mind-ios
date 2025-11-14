import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import '../app_config.dart';
import '../services/sdk_initializer.dart';
import 'webview_screen.dart';

class PushRequestScreen extends StatefulWidget {
  const PushRequestScreen({Key? key}) : super(key: key);

  @override
  State<PushRequestScreen> createState() => _PushRequestScreenState();
}

class _PushRequestScreenState extends State<PushRequestScreen> {
  @override
  void initState() {
    super.initState();
    // Разрешаем все ориентации экрана
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Восстанавливаем все ориентации при закрытии экрана
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppConfig.pushRequestGradient),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Верхняя часть с отступом

                // Центральная часть с логотипом
                Expanded(
                  flex: isLandscape ? 2 : 4,
                  child: Center(
                    child: Container(
                      width: isLandscape ? 200 : 250,
                      height: isLandscape ? 160 : 250,
                      child: const Image(
                        image: AssetImage(
                          AppConfig.pushRequestLogoPath,
                        ),
                      ),
                    ),
                  ),
                ),

                // Нижняя часть с текстами и кнопками
                Expanded(
                  flex: isLandscape ? 3 : 2,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: AppConfig.pushRequestFadeGradient,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isLandscape ? 60 : 30,
                      vertical: 20,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Первый текст
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 5,
                          ),
                          child: Text(
                            'Allow notifications about bonuses and promos',
                            style: TextStyle(
                              fontSize: isLandscape ? 18 : 16,
                              fontWeight: FontWeight.w600,
                              color: AppConfig.titleTextColor,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // Второй текст
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 0,
                          ),
                          child: Text(
                            'Stay tuned with best offers from our casino',
                            style: TextStyle(
                              fontSize: isLandscape ? 16 : 14,
                              fontWeight: FontWeight.w500,
                              color: AppConfig.subtitleTextColor,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // Кнопки
                        Container(
                          width: double.infinity,
                          height: isLandscape ? 40 : 50,
                          //S  margin: const EdgeInsets.only(bottom: 15),
                          child: ElevatedButton(
                            onPressed: () {
                              SdkInitializer.pushRequest(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConfig.yesButtonColor,
                              foregroundColor: Colors.white,
                              elevation: 10,
                              shadowColor: AppConfig.yesButtonShadowColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              'Yes, I Want Bonuses!',
                              style: TextStyle(
                                  fontSize: isLandscape ? 18 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppConfig.yesButtonTextColor),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: isLandscape ? 40 : 50,
                          child: ElevatedButton(
                            onPressed: () {
                              // Обработка нажатия "Скип"
                              SdkInitializer.pushRequestDecline();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WebViewScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0),
                              elevation: 5,
                              shadowColor: Colors.white.withOpacity(0),
                            ),
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                fontSize: isLandscape ? 16 : 16,
                                fontWeight: FontWeight.w600,
                                color: AppConfig.skipTextColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
