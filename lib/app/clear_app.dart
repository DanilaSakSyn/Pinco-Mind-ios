import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:pinco_mind_app/app/main_screen.dart';
import 'package:pinco_mind_app/app/tag_controller.dart';
import 'package:pinco_mind_app/app/task_controller.dart';
import 'package:pinco_mind_app/app/theme_controller.dart';

const CupertinoThemeData _lightTheme = CupertinoThemeData(
  brightness: Brightness.dark,
  primaryColor: AppPalette.darkPrimarySoft,
  primaryContrastingColor: AppPalette.darkTextPrimary,
  scaffoldBackgroundColor: AppPalette.darkSurface,
  barBackgroundColor: Color(0xE61C0135),
  textTheme: CupertinoTextThemeData(
    primaryColor: AppPalette.darkTextPrimary,
    textStyle: TextStyle(
      color: AppPalette.darkTextSecondary,
      fontSize: 16,
      inherit: false,
    ),
    navTitleTextStyle: TextStyle(
      color: AppPalette.darkTextPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      inherit: false,
    ),
    navLargeTitleTextStyle: TextStyle(
      color: AppPalette.darkTextPrimary,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      inherit: false,
    ),
    tabLabelTextStyle: TextStyle(
      color: AppPalette.darkTextSecondary,
      fontSize: 12,
      letterSpacing: 0.2,
      inherit: false,
    ),
  ),
);

const CupertinoThemeData _darkTheme = CupertinoThemeData(
  brightness: Brightness.dark,
  primaryColor: AppPalette.darkPrimary,
  primaryContrastingColor: AppPalette.darkTextPrimary,
  scaffoldBackgroundColor: AppPalette.darkSurface,
  barBackgroundColor: Color(0xF01C0135),
  textTheme: CupertinoTextThemeData(
    primaryColor: AppPalette.darkTextPrimary,
    textStyle: TextStyle(
      color: AppPalette.darkTextSecondary,
      fontSize: 16,
      inherit: false,
    ),
    navTitleTextStyle: TextStyle(
      color: AppPalette.darkTextPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      inherit: false,
    ),
    navLargeTitleTextStyle: TextStyle(
      color: AppPalette.darkTextPrimary,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      inherit: false,
    ),
    tabLabelTextStyle: TextStyle(
      color: AppPalette.darkTextSecondary,
      fontSize: 12,
      letterSpacing: 0.2,
      inherit: false,
    ),
  ),
);

class ClearApp extends StatefulWidget {
  const ClearApp({super.key});

  @override
  State<ClearApp> createState() => _ClearAppState();
}

class _ClearAppState extends State<ClearApp> with WidgetsBindingObserver {
  late final ThemeController _themeController;
  late final TaskController _taskController;
  late final TagController _tagController;

  @override
  void initState() {
    super.initState();
    _themeController = ThemeController();
    _themeController.addListener(_handleThemeChanged);
    _taskController = TaskController();
    _taskController.init();
    _tagController = TagController();
    _tagController.init();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeController.removeListener(_handleThemeChanged);
    _themeController.dispose();
    _taskController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _handleThemeChanged() {
    setState(() {});
  }

  CupertinoThemeData _resolveTheme() {
    switch (_themeController.mode) {
      case ThemeMode.light:
        return _lightTheme;
      case ThemeMode.dark:
        return _darkTheme;
      case ThemeMode.system:
        final Brightness brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.dark ? _darkTheme : _lightTheme;
    }
  }

  @override
  void didChangePlatformBrightness() {
    if (_themeController.mode == ThemeMode.system) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      notifier: _themeController,
      child: TagScope(
        notifier: _tagController,
        child: TaskScope(
          notifier: _taskController,
          child: CupertinoApp(
            debugShowCheckedModeBanner: false,
            home: const MainScreen(),
            theme: _resolveTheme(),
          ),
        ),
      ),
    );
  }
}
