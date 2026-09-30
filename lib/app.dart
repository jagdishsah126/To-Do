import 'package:flutter/material.dart';
import 'package:personal_todo/data/backup_service.dart';
import 'package:personal_todo/data/settings_repository.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/domain/app_settings.dart';
import 'package:personal_todo/domain/enums.dart';
import 'package:personal_todo/features/calendar/calendar_page.dart';
import 'package:personal_todo/features/history/history_page.dart';
import 'package:personal_todo/features/search/search_page.dart';
import 'package:personal_todo/features/settings/settings_page.dart';
import 'package:personal_todo/features/statistics/statistics_page.dart';
import 'package:personal_todo/features/today/today_page.dart';
import 'package:personal_todo/features/upcoming/upcoming_page.dart';
import 'package:personal_todo/services/notification_service.dart';

class TodoApp extends StatefulWidget {
  const TodoApp({
    super.key,
    required this.tasks,
    required this.categories,
    required this.settingsRepo,
    required this.notifications,
    required this.backup,
    required this.initialSettings,
  });

  final TaskRepository tasks;
  final CategoryRepository categories;
  final SettingsRepository settingsRepo;
  final NotificationService notifications;
  final BackupService backup;
  final AppSettings initialSettings;

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  late AppSettings _settings = widget.initialSettings;
  int _index = 0;
  int _token = 0;

  void _refresh() => setState(() => _token++);

  ThemeMode get _themeMode => switch (_settings.theme) {
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
        ThemePreference.system => ThemeMode.system,
      };

  late final List<Widget> _pages = [
    TodayPage(
      key: ValueKey('today-$_token'),
      tasks: widget.tasks,
      categories: widget.categories,
      notifications: widget.notifications,
      settings: _settings,
      onChanged: _refresh,
      onOpenSearch: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchPage(
              tasks: widget.tasks,
              categories: widget.categories,
              notifications: widget.notifications,
              settings: _settings,
              onChanged: _refresh,
            ),
          ),
        );
        _refresh();
      },
    ),
    UpcomingPage(
      key: ValueKey('upcoming-$_token'),
      tasks: widget.tasks,
      categories: widget.categories,
      notifications: widget.notifications,
      settings: _settings,
      onChanged: _refresh,
    ),
    CalendarPage(
      key: ValueKey('calendar-$_token'),
      tasks: widget.tasks,
      categories: widget.categories,
      notifications: widget.notifications,
      settings: _settings,
      onChanged: _refresh,
    ),
    StatisticsPage(
      key: ValueKey('stats-$_token'),
      tasks: widget.tasks,
    ),
    SettingsPage(
      settingsRepo: widget.settingsRepo,
      notifications: widget.notifications,
      backup: widget.backup,
      tasks: widget.tasks,
      categories: widget.categories,
      settings: _settings,
      onSettingsChanged: (value) {
        setState(() => _settings = value);
        _refresh();
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Todo',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D4AA),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.black.withOpacity(0.08),
              width: 1,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFF00D4AA).withOpacity(0.2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFF00D4AA));
            }
            return const IconThemeData(color: Colors.black38);
          }),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF00D4AA),
          foregroundColor: Colors.black,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.black.withOpacity(0.1),
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1A1F2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D4AA),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 2),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFF00D4AA).withOpacity(0.2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFF00D4AA));
            }
            return const IconThemeData(color: Colors.white54);
          }),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF00D4AA),
          foregroundColor: Colors.black,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.white.withOpacity(0.1),
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1A1F2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(
            key: ValueKey(_index),
            child: _pages[_index],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            backgroundColor: Colors.transparent,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.today_outlined),
                selectedIcon: Icon(Icons.today),
                label: 'Today',
              ),
              NavigationDestination(
                icon: Icon(Icons.upcoming_outlined),
                selectedIcon: Icon(Icons.upcoming),
                label: 'Upcoming',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'Calendar',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Stats',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
