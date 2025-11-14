import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../services/sdk_initializer.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewScreen extends StatefulWidget {
  final String initialUrl;

  const WebViewScreen({super.key, this.initialUrl = 'https://flutter.dev'});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class UrlLauncherService {
  static Future<void> launchInBrowser({
    required String url,
    //required BuildContext context,
  }) async {
    try {
      final Uri uri = Uri.parse(url);

      // if (!await canLaunchUrl(uri)) {
      //   //  _showErrorSnackbar(context, 'Не удалось открыть ссылку');
      //   return;
      // }

      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      // _showErrorSnackbar(context, 'Ошибка: $e');
    }
  }

  static void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

Future<void> _launchURL(String url) async {
  // NativeMethodCaller.callSwiftMethodWithParams({'url': url});
  // await LaunchApp.openApp(
  //   iosUrlScheme: url, // Example for Instagram
  // );
  UrlLauncherService.launchInBrowser(
    url: url,
  );

  // if (await canLaunchUrl(Uri.parse(url))) {
  //   await launchUrl(
  //     Uri.parse(url),
  //     mode: LaunchMode.externalApplication, // Or other modes as needed
  //   );
  // } else {
  //   throw 'Could not launch $url';
  // }
}

class NativeMethodCaller {
  static const MethodChannel _channel =
      MethodChannel('com.yourapp/native_methods');

  static Future<void> callSwiftMethodWithParams(
      Map<String, dynamic> params) async {
    print("callSwiftMethodWithParams ${params.toString()}");
    try {
      await _channel.invokeMethod('callSwiftMethodWithParams', params);
    } on PlatformException catch (e) {
      print("Failed to call Swift method: '${e.message}'");
    }
  }
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final PlatformWebViewController controller;
  bool isLoading = true;
  String currentUrl = '';

  bool get kDebugMode => true;

  @override
  void initState() {
    super.initState();

    // Проверяем, есть ли сохраненная ссылка в хранилище
    String? savedUrl = SdkInitializer.receivedUrl;
    String urlToLoad = savedUrl ?? widget.initialUrl;
    if (SdkInitializer.pushURL != null) {
      urlToLoad = SdkInitializer.pushURL!;
    }
    print("3 showWeb pushURL ${SdkInitializer.pushURL}");
    print("3 surlToLoad -${urlToLoad}-");
    controller = WebKitWebViewController(
      WebKitWebViewControllerCreationParams(
        mediaTypesRequiringUserAction: const {},
        allowsInlineMediaPlayback: true,
      ),
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(false)
      ..setPlatformNavigationDelegate(
        WebKitNavigationDelegate(
          const PlatformNavigationDelegateCreationParams(),
        )
          ..setOnPageStarted((String url) {
            setState(() {
              isLoading = true;
              currentUrl = url;
            });
          })
          ..setOnPageFinished((String url) {
            setState(() {
              isLoading = false;
              currentUrl = url;
            });
          })
          ..setOnHttpError((HttpResponseError error) {
            debugPrint(
              'Error occurred on page: ${error.response?.statusCode}',
            );
          })
          ..setOnWebResourceError((WebResourceError error) {
            // print(
            //   "error " +
            //       error.errorCode.toString() +
            //       "   url " +
            //       error.url!,
            // );
            if (error.errorCode == -1007 ||
                error.errorCode == -9 ||
                error.errorCode == -0) {
              if (error.url != null) {
                controller.loadRequest(
                  LoadRequestParams(uri: Uri.parse(error.url!)),
                );
                return;
              }
            }
            // if (error.url!.contains("http://")) return;
            // if (error.url!.contains("https://")) return;
            // _launchURL(error.url!);
          })
          ..setOnUrlChange((UrlChange change) {
            //  debugPrint('url change to ${change.url}');
            if (change.url!.contains("http://")) return;
            if (change.url!.contains("https://")) return;
            print(change.url);
            _launchURL(change.url!); //change.url!);
          }),
      )
      ..setOnCanGoBackChange((onCanGoBackChangeCallback) {
        controller.canGoBack().then((onValue) {
          if (kDebugMode) {
            // print(
            //   "onValue " +
            //       onValue.toString() +
            //       " onCanGoBackChangeCallback " +
            //       onCanGoBackChangeCallback.toString(),
            // );
          }
          onCanGoBackChangeCallback = onValue;
        });
      })
      ..setOnPlatformPermissionRequest((
        PlatformWebViewPermissionRequest request,
      ) {
        debugPrint(
          'requesting permissions for ${request.types.map((WebViewPermissionResourceType type) => type.name)}',
        );
        request.grant();
      })
      ..setAllowsBackForwardNavigationGestures(true)
      ..getUserAgent().then((String? userAgent) {
        controller.setUserAgent(
          userAgent?.replaceAll("; wv", "").replaceAll("; wv", ""),
        );

        controller.loadRequest(
          LoadRequestParams(uri: Uri.parse(urlToLoad)),
        );
      });

    //controller.getSettings().setMediaPlaybackRequiresUserGesture(false);

    // Создаем контроллер WebView
    // controller = PlatformWebViewController(
    //   WebKitWebViewControllerCreationParams(allowsInlineMediaPlayback: true),
    // );

    //   controller
    //   controller

    //     ..setJavaScriptMode(JavaScriptMode.unrestricted)
    //     // ..setAllowsBackForwardNavigationGestures(true)
    //     ..setPlatformNavigationDelegate(
    //       const PlatformNavigationDelegateCreationParams(),
    //     )
    //     ..setOnPageStarted((String url) {})
    //     ..setOnPageFinished((String url) {})
    //     ..setOnWebResourceError((WebResourceError error) {
    //       // print('Ошибка WebView: ${error.description}');
    //     })
    //     ..loadRequest(Uri.parse(urlToLoad));
    // });

    // if (controller is WebKitWebViewController) {
    //   (controller as WebKitWebViewController)
    //       .setAllowsBackForwardNavigationGestures(true);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: PlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams(controller: controller),
        ).build(context),
      ),
    );
  }
}
