import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/notifications/reminder_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/rpg_colors.dart';
import 'features/budget/presentation/pages/budget_page.dart';
import 'features/japanese/presentation/pages/japanese_page.dart';
import 'features/mindfulness/presentation/pages/mindfulness_page.dart';
import 'features/player/presentation/pages/player_page.dart';
import 'features/quests/presentation/pages/quests_page.dart';
import 'features/routines/presentation/controllers/routine_controller.dart';
import 'features/routines/presentation/pages/routines_page.dart';
import 'features/routines/presentation/widgets/routine_tab_icon.dart';
import 'features/wealth/presentation/pages/wealth_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ujwiflvjioyjneczeoyi.supabase.co',
    anonKey: 'sb_publishable_AXfZD4pfX3Y2BS8e2U-Wcg_GbzngalT',
  );

  // Never let a notification problem stop the app from starting.
  try {
    await ReminderService.instance.init();
  } catch (_) {}

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

class _ShellState extends State<_Shell> with WidgetsBindingObserver {
  int _index = 0;

  /// Lives here rather than inside the page so the Daily tab can light up
  /// without the page being open.
  late final RoutineController _routines;

  /// The day the routines were last loaded for. Coming back to the app after
  /// midnight has to reset the board, or yesterday's ticks read as today's.
  late DateTime _loadedFor;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _routines = RoutinesPage.createController();
    _loadedFor = _routines.state.today;
    _routines.load();

    _pages = [
      const PlayerPage(),
      RoutinesPage(controller: _routines),
      const JapanesePage(),
      const MindfulnessPage(),
      const WealthPage(),
      const BudgetPage(),
      const QuestsPage(),
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routines.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    // Only worth a round trip when the date actually turned over.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (today == _loadedFor) return;

    _loadedFor = today;
    _routines.load();
  }

  static const _tabs = <_TabDef>[
    _TabDef(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Player'),
    _TabDef(
      icon: Icons.checklist_rtl,
      activeIcon: Icons.checklist,
      label: 'Daily',
      routineBadge: true,
    ),
    _TabDef(icon: Icons.translate_outlined, activeIcon: Icons.translate, label: 'JP'),
    _TabDef(icon: Icons.self_improvement_outlined, activeIcon: Icons.self_improvement, label: 'Mind'),
    _TabDef(icon: Icons.account_balance_outlined, activeIcon: Icons.account_balance, label: 'Wealth'),
    _TabDef(icon: Icons.wallet_outlined, activeIcon: Icons.wallet, label: 'Budget'),
    _TabDef(icon: Icons.map_outlined, activeIcon: Icons.map, label: 'Quests'),
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
                      if (tab.routineBadge)
                        RoutineTabIcon(
                          controller: _routines,
                          icon: selected ? tab.activeIcon : tab.icon,
                          selected: selected,
                        )
                      else
                        Icon(
                          selected ? tab.activeIcon : tab.icon,
                          size: 20,
                          color: selected
                              ? RpgColors.textPrimary
                              : RpgColors.textMuted,
                        ),
                      const SizedBox(height: 3),
                      if (tab.routineBadge)
                        RoutineTabLabel(
                          controller: _routines,
                          label: tab.label,
                          selected: selected,
                        )
                      else
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

  /// Lights this tab while routines are still open today.
  final bool routineBadge;

  const _TabDef({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.routineBadge = false,
  });
}
