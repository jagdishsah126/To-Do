import 'package:flutter/material.dart';
import 'package:personal_todo/data/backup_service.dart';
import 'package:personal_todo/data/settings_repository.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/domain/app_settings.dart';
import 'package:personal_todo/domain/enums.dart';
import 'package:personal_todo/features/calendar/calendar_page.dart';
import 'package:personal_todo/features/search/search_page.dart';
import 'package:personal_todo/features/settings/settings_page.dart';
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
    SettingsPage(
      settingsRepo: widget.settingsRepo,
      notifications: widget.notifications,
      backup: widget.backup,
      tasks: widget.tasks,
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
          seedColor: const Color(0xFF1F6F5F),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAF9),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 3,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF1F6F5F).withOpacity(0.15),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F6F5F),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 3,
          indicatorColor: const Color(0xFF1F6F5F).withOpacity(0.25),
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
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
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
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
