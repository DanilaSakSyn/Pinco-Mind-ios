import 'package:flutter/cupertino.dart';
import 'package:pinco_mind_app/app/features/board/board_screen.dart';
import 'package:pinco_mind_app/app/features/home/home_screen.dart';
import 'package:pinco_mind_app/app/features/stats/stats_screen.dart';
import 'package:pinco_mind_app/app/features/settings/settings_screen.dart';
import 'package:pinco_mind_app/app/theme_controller.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppPalette.darkBackgroundGradient,
      ),
      child: CupertinoTabScaffold(
        backgroundColor: CupertinoColors.transparent,
        tabBar: CupertinoTabBar(
          backgroundColor: AppPalette.darkSurfaceElevated.withOpacity(0.82),
          activeColor: theme.primaryColor,
          inactiveColor: AppPalette.darkTextSecondary,
          border: Border(
            top: BorderSide(
              color: AppPalette.darkPrimarySoft.withOpacity(0.35),
              width: 0.6,
            ),
          ),
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house_fill),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.square_list_fill),
              label: 'Board',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.chart_bar_alt_fill),
              label: 'Stats',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.gear_solid),
              label: 'Settings',
            ),
          ],
        ),
        tabBuilder: (BuildContext context, int index) {
          switch (index) {
            case 0:
              return CupertinoTabView(
                builder: (BuildContext context) {
                  return const HomeScreen();
                },
              );
            case 1:
              return CupertinoTabView(
                builder: (BuildContext context) {
                  return const BoardScreen();
                },
              );
            case 2:
              return CupertinoTabView(
                builder: (BuildContext context) {
                  return const StatsScreen();
                },
              );
            case 3:
            default:
              return CupertinoTabView(
                builder: (BuildContext context) {
                  return const SettingsScreen();
                },
              );
          }
        },
      ),
    );
  }
}

// Removed placeholder screen in favor of dedicated HomeScreen implementation.
