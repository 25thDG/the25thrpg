import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/rpg_colors.dart';
import 'features/creation/presentation/pages/creation_page.dart';
import 'features/japanese/presentation/pages/japanese_page.dart';
import 'features/mindfulness/presentation/pages/mindfulness_page.dart';
import 'features/player/presentation/pages/player_page.dart';
import 'features/social/presentation/pages/social_page.dart';
import 'features/sport/presentation/pages/sport_page.dart';
import 'features/wealth/presentation/pages/wealth_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ujwiflvjioyjneczeoyi.supabase.co',
    anonKey: 'sb_publishable_AXfZD4pfX3Y2BS8e2U-Wcg_GbzngalT',
  );

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The 25th',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _Shell(),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _index = 0;

  static const _pages = <Widget>[
    PlayerPage(),
    JapanesePage(),
    MindfulnessPage(),
    WealthPage(),
    CreationPage(),
    SocialPage(),
    SportPage(),
  ];

  static const _tabs = <_TabDef>[
    _TabDef(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Player'),
    _TabDef(icon: Icons.translate_outlined, activeIcon: Icons.translate, label: 'JP'),
    _TabDef(icon: Icons.self_improvement_outlined, activeIcon: Icons.self_improvement, label: 'Mind'),
    _TabDef(icon: Icons.account_balance_outlined, activeIcon: Icons.account_balance, label: 'Wealth'),
    _TabDef(icon: Icons.brush_outlined, activeIcon: Icons.brush, label: 'Create'),
    _TabDef(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Social'),
    _TabDef(icon: Icons.fitness_center_outlined, activeIcon: Icons.fitness_center, label: 'Sport'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: RpgColors.panelBg,
          border: Border(top: BorderSide(color: RpgColors.border, width: 0.5)),
        ),
        padding: EdgeInsets.only(bottom: bottomPad),
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final tab = _tabs[i];
            final selected = i == _index;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _index = i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? tab.activeIcon : tab.icon,
                        size: 20,
                        color: selected
                            ? RpgColors.textPrimary
                            : RpgColors.textMuted,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tab.label,
                        style: TextStyle(
                          color: selected
                              ? RpgColors.textPrimary
                              : RpgColors.textMuted,
                          fontSize: 9,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _TabDef {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabDef({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
