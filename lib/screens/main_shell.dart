import 'dart:async';
import 'package:flutter/material.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/services/notification_service.dart';
import 'package:currensee/services/notification_store.dart';
import 'package:currensee/utils/toast.dart';
import 'package:currensee/screens/home/widgets/app_menu_drawer.dart';
import 'package:currensee/screens/home/home_screen.dart';
import 'rates_screen.dart';
import 'convert_screen.dart';
import 'profile_screen.dart';


class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;
  StreamSubscription? _pushSub;

  @override
  void initState() {
    super.initState();
    NotificationService.start();
    NotificationStore.instance.start();
    // A push that arrives while the app is open: refresh the badge and show it.
    _pushSub = NotificationService.foreground.listen((m) {
      NotificationStore.instance.refresh();
      final n = m.notification;
      if (n != null && mounted) {
        toast(context, [n.title, n.body].whereType<String>().join(': '));
      }
    });
  }

  @override
  void dispose() {
    _pushSub?.cancel();
    super.dispose();
  }

  void _openMenu() => _scaffoldKey.currentState?.openEndDrawer();
  void _go(int i) => setState(() => _index = i);

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.show_chart_rounded, 'Rates'),
    (Icons.swap_horiz_rounded, 'Convert'),
    (Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const AppMenuDrawer(),
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onOpenMenu: _openMenu, onGoToTab: _go),
          RatesScreen(onOpenMenu: _openMenu),
          ConvertScreen(onOpenMenu: _openMenu),
          ProfileScreen(onOpenMenu: _openMenu),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.emeraldBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _go(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_items[i].$1,
                                size: 28,
                                color: i == _index ? AppColors.goldWarm : Colors.white54),
                            const SizedBox(height: 2),
                            Text(_items[i].$2,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: i == _index ? AppColors.goldWarm : Colors.white54)),
                            const SizedBox(height: 3),
                            Container(
                              height: 3,
                              width: 34,
                              decoration: BoxDecoration(
                                color: i == _index ? AppColors.goldWarm : Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}