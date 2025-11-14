import 'dart:io' show Platform;
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/services.dart';
import '../../app/clear_app.dart';
import '../../firebase_options.dart';
import '../app_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_messaging_service.dart';
import '../screens/no_internet_connection.dart';
import 'push_request_control.dart';
import '../screens/push_request_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/webview_screen.dart';

class SdkInitializer {
  static BuildContext? _context;
  static AppsflyerSdk? _appsflyerSdk;

  // Хранилище для переменных во время выполнения приложения
  static final Map<String, dynamic> _runtimeStorage = {};
  static Map<String, dynamic> _convrtsion = {};

  // Геттеры для удобного доступа к часто используемым переменным
  static String? receivedUrl;
  static String? pushURL;
  static String? get conversionData =>
      _runtimeStorage['conversionData'] as String?;
  static Map<String, dynamic>? get serverResponse =>
      _runtimeStorage['serverResponse'] as Map<String, dynamic>?;
  static String? get apnsToken => _runtimeStorage['apnsToken'] as String?;
  static SharedPreferences? prefs;

  static PushRequestData? pushRequestData;

  static String deep_link_sub1 = "";
  static String deep_link_value = "";

  /// Сохраняет содержимое _runtimeStorage в строку JSON
  static String saveRuntimeStorage() {
    try {
      return json.encode(_runtimeStorage);
    } catch (e) {
      //  print('Ошибка при сохранении _runtimeStorage: $e');
      return '{}';
    }
  }

  /// Загружает содержимое JSON-строки в _runtimeStorage (старые значения перезаписываются)
  static void loadRuntimeStorage(String jsonString) {
    try {
      Map<String, dynamic> map = json.decode(jsonString);
      _runtimeStorage
        ..clear()
        ..addAll(map);
    } catch (e) {
      // print('Ошибка при загрузке _runtimeStorage: $e');
    }
  }

  // Методы для работы с хранилищем
  static void setValue(String key, dynamic value) {
    _runtimeStorage[key] = value;
    saveRuntimeStorageToDevice();
  }

  static Future<void> saveRuntimeStorageToDevice() async {
    try {
      final jsonString = saveRuntimeStorage();
      await prefs!.setString('runtimeStorage', jsonString);
      //  print("save data $jsonString");
    } catch (e) {
      print('Ошибка при сохранении runtimeStorage на девайсе: $e');
    }
  }

  static Future<void> loadRuntimeStorageToDevice() async {
    try {
      var json = await prefs!.getString('runtimeStorage');
      loadRuntimeStorage(json!);
      print('runtimeStorage успешно загружен');
    } catch (e) {
      print('Ошибка при сохранении runtimeStorage на девайсе: $e');
    }
  }

  static dynamic getValue(String key) {
    return _runtimeStorage[key];
  }

  static bool hasValue(String key) {
    return _runtimeStorage.containsKey(key);
  }

  static void clearStorage() {
    _runtimeStorage.clear();
  }

  static Map<String, dynamic> getAllValues() {
    return Map.from(_runtimeStorage);
  }

  static void showApp(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const ClearApp()),
      (route) => false,
    );
  }

  static void showWeb(BuildContext context) {
    print('3 showWeb');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WebViewScreen()),
      (route) => false,
    );
  }

  static const MethodChannel _channel =
      MethodChannel('com.yourapp/native_methods');

  static Future<void> callSwiftMethod() async {
    try {
      await _channel.invokeMethod('callSwiftMethod');
    } on PlatformException catch (e) {
      print("Failed to call Swift method: '${e.message}'");
    }
  }

  static Future<void> initAll(BuildContext context) async {
    var isNotInternet =
        await NoInternetConnectionScreen.checkInternetConnection();

    // print('isNotInternet =' + isNotInternet.toString());
    if (!isNotInternet) {
      NoInternetConnectionScreen.showIfNoInternet(context);
      return;
    }
    prefs = await SharedPreferences.getInstance();
    await loadRuntimeStorageToDevice();

    if (hasValue("pushRequestData")) {
      pushRequestData = PushRequestData.fromJson(getValue("pushRequestData"));
    } else {
      pushRequestData = PushRequestData();
      //print("new PushRequestData");
    }
    _context = context;

    var isFirstStart = !hasValue("isFirstStart");
    if (!isFirstStart) {
      var isOrganic = getValue("Organic");
      if (!isOrganic) {
        Map<String, dynamic> conversion = getValue("conversionData");
        print(conversion);
        receivedUrl = await makeConversion(conversion);
        if (PushRequestControl.shouldShowPushRequest(pushRequestData!)) {
          Navigator.pushAndRemoveUntil(
            _context!,
            MaterialPageRoute(builder: (context) => const PushRequestScreen()),
            (route) => false,
          );
        } else {
          final initialMessage =
              await FirebaseMessaging.instance.getInitialMessage();
          if (initialMessage != null) {
            _onMessageOpenedApp(initialMessage);
          }
          FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
          showWeb(context);
        }
      } else {
        showApp(context);
      }
      return;
    }

    // WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) async {
    //   final status =
    //       await AppTrackingTransparency.requestTrackingAuthorization();
    // });
    //initAppsFlyer();
  }

  static void _onMessageOpenedApp(RemoteMessage message) {
    print('1 Notification caused the app to open: ${message.data.toString()}');
    SdkInitializer.pushURL = message.data['url'];

    // TODO: Add navigation or specific handling based on message data
  }

  static Future<String> makeConversion(
    Map<String, dynamic> conversionMap, {
    String? apnsToken,
    bool isLoad = true,
  }) async {
    conversionMap.addEntries([
      MapEntry("store_id", "id" + AppConfig.appsFlyerAppId),
      MapEntry("bundle_id", AppConfig.bundleId),
      MapEntry("locale", AppConfig.locale),
      MapEntry("os", AppConfig.os),
      MapEntry("firebase_project_id", AppConfig.firebaseProjectId),
    ]);

    if (apnsToken != null) {
      conversionMap.addEntries([MapEntry("push_token", apnsToken)]);
    }
    //print(conversionMap);
    var result = await sendPostRequest(
      body: conversionMap,
      url: AppConfig.endpoint + "/config.php",
    );

    // if (isLoad) {
    //   onEndRequest(result);
    // }
    if (result == null) return "";
    setValue('serverResponse', result);

    if (!result.containsKey("url")) return "";

    return result['url'];
  }

  static void onEndRequest(String? url) {
    if (url == null || url == "") {
      print('not url');
      setValue("Organic", true);
      setValue("isFirstStart", true);

      showApp(_context!);

      return;
    }
    setValue("Organic", false);
    setValue("isFirstStart", true);

    // Сохраняем полный ответ сервера
    setValue('serverResponse', url);

    //print(mapToJsonString(map));

    // print("url: " + url);

    // Сохраняем полученную ссылку в хранилище
    receivedUrl = url;
    setValue('urlReceivedAt', DateTime.now().toIso8601String());
    print('url');

    if (PushRequestControl.shouldShowPushRequest(pushRequestData!)) {
      print('url1');
      Navigator.pushAndRemoveUntil(
        _context!,
        MaterialPageRoute(builder: (context) => const PushRequestScreen()),
        (route) => false,
      );
    } else {
      print('url2');
      Navigator.push(
        _context!,
        MaterialPageRoute(builder: (context) => const WebViewScreen()),
      );
    }
  }

  static bool isHasConversion = false;
  static void initAppsFlyer() {
    final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: AppConfig.appsFlyerDevKey,
      appId: AppConfig.appsFlyerAppId,
      showDebug: true,
      timeToWaitForATTUserAuthorization: 15,
      manualStart: true,
    );
    _appsflyerSdk = AppsflyerSdk(options);
    // App open attribution callback
    print('add af');
    _appsflyerSdk!.onAppOpenAttribution((res) {
      print("onAppOpenAttribution res: $res");
    });
    _appsflyerSdk!.setOneLinkCustomDomain(['']);
    // Deep linking callback
    _appsflyerSdk!.onDeepLinking((DeepLinkResult dp) {
      switch (dp.status) {
        case Status.FOUND:
          print(dp.deepLink?.toString());
          print("onDeepLinking res: $dp");

          var map = dp.deepLink!.clickEvent;
          //_convrtsion.addEntries(map as Iterable<MapEntry<String, dynamic>>);
          _convrtsion.addAll(map);
          print(
              'deep_link_value=$deep_link_value deep_link_sub1=$deep_link_sub1|');
          break;
        case Status.NOT_FOUND:
          print("deep link not found");
          break;
        case Status.ERROR:
          print("deep link error: ${dp.error}");
          break;
        case Status.PARSE_ERROR:
          print("deep link status parsing error");
          break;
      }
      print("onDeepLinking res: $dp");
    });

    _appsflyerSdk
        ?.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    )
        .then((value) {
      print('_appsflyerSdk initSdk');

      // _appsflyerSdk!
      //     .onDeepLinking((DeepLinkResult dl) => (DeepLinkResult dl) {

      //     });
      _appsflyerSdk?.onInstallConversionData((res) {
        if (isHasConversion) return;
        isHasConversion = true;
        _appsflyerSdk?.getAppsFlyerUID().then((value) async {
          if (value == null) return;
          Map<String, dynamic> conversionMap = res["payload"];

          print("start load conversion 1");
          print("af_sub2: ${conversionMap['af_sub1']}");

          print(_convrtsion);
          print("start load conversion 2");

          print(conversionMap);

          print("start load conversion 3");

          for (var entry in conversionMap.entries) {
            //if (_convrtsion.containsKey(entry.key)) continue;
            if (entry.value != '') {
              _convrtsion[entry.key] = entry.value;

              print(
                  '|${entry.key} - ${entry.value} |${_convrtsion[entry.key]}');
            }
          }

          // _convrtsion.addAll(conversionMap);
          // _convrtsion
          //     .addEntries(conversionMap as Iterable<MapEntry<String, dynamic>>);
          if (_convrtsion != null) {
            _convrtsion.addEntries([MapEntry("af_id", value)]);

            setValue('conversionData', _convrtsion);
            var url = await makeConversion(_convrtsion);
            print("url -" + url);
            onEndRequest(url);
          }
        });

        // if (res is Map<dynamic, dynamic>) {
        //    Map<String, dynamic>? conversionMap =(res as Map<dynamic, dynamic>)["asd"];
        // }
      });
      // Starting the SDK with optional success and error callbacks
      _appsflyerSdk?.startSDK(
        onSuccess: () {
          print("AppsFlyer SDK initialized successfully.");
        },
        onError: (int errorCode, String errorMessage) {
          print(options.afDevKey + " " + options.appId);
          print(
            "Error initializing AppsFlyer SDK: Code $errorCode - $errorMessage",
          );
        },
      );
    });
    // Initialization of the AppsFlyer SDK

    // Starting the SDK with optional success and error callbacks
    // AppsFlyerOptions appsFlyerOptions = AppsFlyerOptions(
    //   afDevKey: 'zvxjwZLB7ErfKkprZ9BueZ',
    //   appId: AppConfig.appsFlyerAppId,
    // ); // Optional field

    // _appsflyerSdk = AppsflyerSdk(appsFlyerOptions);
    // _appsflyerSdk!.startSDK(
    //   onSuccess: () {
    //     print("AppsFlyer SDK initialized successfully.");
    //   },
    //   onError: (int errorCode, String errorMessage) {
    //     print(
    //       "Error initializing AppsFlyer SDK: Code $errorCode - $errorMessage",
    //     );
    //   },
    // );
  }

  /// Запрашивает APNS токен через FirebaseMessaging
  static Future<String?> requestAPNSToken() async {
    try {
      // Запрашиваем разрешение на пуш-уведомления (для iOS запрос обязателен)
      await FirebaseMessaging.instance.requestPermission();

      // Убеждаемся, что FCM token получен (это запустит регистрацию и выдачу APNS токена на iOS)
      var token = await FirebaseMessaging.instance.getAPNSToken();
      print("first token");
      print(token);
      print(DefaultFirebaseOptions.currentPlatform.projectId);
      String? apnsToken;
      int retries = 10;
      // Ждём пока APNS токен не станет доступен
      for (int i = 0; i < retries; i++) {
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null && apnsToken.isNotEmpty) {
          print('APNS токен получен: $apnsToken');
          return apnsToken;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
      print('APNS токен не получен (timeout)');
      return null;
    } catch (e) {
      print('Ошибка при получении APNS токена: $e');
      return null;
    }
  }

  static bool isIOSSimulator() {
    return false;
    if (!Platform.isIOS) return false;

    // Проверяем переменные окружения симулятора
    return Platform.environment.containsKey('SIMULATOR_DEVICE_NAME') ||
        Platform.environment.containsKey('SIMULATOR_HOST_HOME') ||
        Platform.environment.containsKey('SIMULATOR_UDID');
  }

  static Future<void> pushRequest(BuildContext context) async {
    await Firebase.initializeApp();

    var token = await FirebaseMessagingService.InitPushAndGetToken();
    if (token == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WebViewScreen()),
        (route) => false,
      );
      return;
    }

    PushRequestControl.acceptPushRequest(pushRequestData!);

    setValue("pushRequestData", pushRequestData?.toJson());
    _convrtsion = SdkInitializer.getValue('conversionData');
    if (_convrtsion is Map<String, dynamic>) {
      print("makeConversion 2");
      var url = await SdkInitializer.secondMakeConversion(
        _convrtsion,
        apnsToken: token,
        isLoad: false,
      );
      setValue(url, "receivedUrl");
      print("pushRequest ");
      _runtimeStorage['receivedUrl'] = url;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WebViewScreen()),
        (route) => false,
      );
    }
  }

  static Future<String> secondMakeConversion(
    Map<String, dynamic> conversionMap, {
    String? apnsToken,
    bool isLoad = true,
  }) async {
    conversionMap.addEntries([MapEntry("push_token", apnsToken)]);

    print(conversionMap["firebase_project_id"]);

    print("with token " + conversionMap.toString());
    setValue("", conversionMap);
    var result = await sendPostRequest(
      body: conversionMap,
      url: AppConfig.endpoint + "/config.php",
    );

    // if (isLoad) {
    //   onEndRequest(result);
    // }
    if (result == null) return "";
    setValue('serverResponse', result);
    if (!result.containsKey("url")) return "";
    return result['url'];
  }

  static void pushRequestDecline() {
    PushRequestControl.declinePushRequest(pushRequestData!);
    setValue("pushRequestData", pushRequestData?.toJson());
  }
}

Map<String, dynamic> parseJsonFromString(String jsonString) {
  print("1 " + jsonString);
  String cleanedString = jsonString.trim();
  print("2 " + cleanedString);
  // Парсим JSON строку в Map
  Map<String, dynamic> jsonMap = jsonDecode(cleanedString);

  // print("3 " + jsonMap.length.toString());
  return jsonMap;
}

String mapToJsonString(Map<String, dynamic> map) {
  try {
    // Преобразуем Map в JSON строку с красивым форматированием
    String jsonString = json.encode(map);
    return jsonString;
  } catch (e) {
    print('Ошибка преобразования в JSON: $e');
    return '{}';
  }
}

Future<Map<String, dynamic>?> sendPostRequest({
  required String url,
  required Map<String, dynamic> body,
  Map<String, String>? headers,
  Duration timeout = const Duration(seconds: 30),
}) async {
  print(body);
  try {
    // Подготавливаем заголовки
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    // Отправляем POST запрос
    http.Response response = await http
        .post(Uri.parse(url), headers: requestHeaders, body: json.encode(body))
        .timeout(timeout);

    // Проверяем статус ответа
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Успешный ответ
      Map<String, dynamic> result = json.decode(response.body);
      return result;
    } else {
      // Ошибка HTTP
      print('HTTP Error: ${response.statusCode} - ${response.body}');
      return null;
    }
  } catch (e) {
    print('Ошибка запроса: $e');
    return null;
  }
}
