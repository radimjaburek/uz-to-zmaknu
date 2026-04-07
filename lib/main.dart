import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.loadAll();
  runApp(const MyApp());
}

// ==================== GLOBÁLNÍ DATA ====================
class Global {
  static List<Habit> habits = [];
  static List<Task> tasks = [];
  static List<Reminder> reminders = [];
  static List<Wisdom> wisdoms = [];
  static List<Category> categories = [];
}

// ==================== MODELY ====================
class Reminder {
  String text;
  DateTime date;
  Reminder({required this.text, required this.date});
  Map<String, dynamic> toJson() => {
        'text': text,
        'date': date.toIso8601String(),
      };
  factory Reminder.fromJson(Map<String, dynamic> json) =>
      Reminder(text: json['text'], date: DateTime.parse(json['date']));
}

class PerformanceRecord {
  final DateTime date;
  final String status;
  PerformanceRecord({required this.date, required this.status});
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'status': status,
      };
  factory PerformanceRecord.fromJson(Map<String, dynamic> json) =>
      PerformanceRecord(
        date: DateTime.parse(json['date']),
        status: json['status'],
      );
}

class Habit {
  String name, reason, fullDef, partialDef;
  List<String> days;
  List<PerformanceRecord> history;
  Habit({
    required this.name,
    this.reason = '',
    this.fullDef = '',
    this.partialDef = '',
    required this.days,
    this.history = const [],
  });
  Map<String, dynamic> toJson() => {
        'name': name,
        'reason': reason,
        'fullDef': fullDef,
        'partialDef': partialDef,
        'days': days,
        'history': history.map((e) => e.toJson()).toList(),
      };
  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        name: json['name'],
        reason: json['reason'] ?? '',
        fullDef: json['fullDef'] ?? '',
        partialDef: json['partialDef'] ?? '',
        days: List<String>.from(json['days']),
        history: (json['history'] as List?)
                ?.map((e) => PerformanceRecord.fromJson(e))
                .toList() ??
            [],
      );
}

class Task {
  String name, description, fullDef, partialDef, status;
  DateTime? dueDate, completedDate;
  int durationMinutes;
  int? actualTimeSpent; // Nové pole pro skutečně strávený čas
  Task({
    required this.name,
    this.description = '',
    this.durationMinutes = 0,
    this.fullDef = '',
    this.partialDef = '',
    this.dueDate,
    this.status = 'pending',
    this.completedDate,
    this.actualTimeSpent,
  });
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'durationMinutes': durationMinutes,
        'fullDef': fullDef,
        'partialDef': partialDef,
        'dueDate': dueDate?.toIso8601String(),
        'status': status,
        'completedDate': completedDate?.toIso8601String(),
        'actualTimeSpent': actualTimeSpent,
      };
  factory Task.fromJson(Map<String, dynamic> json) => Task(
        name: json['name'],
        description: json['description'] ?? '',
        durationMinutes: json['durationMinutes'] ?? 0,
        fullDef: json['fullDef'] ?? '',
        partialDef: json['partialDef'] ?? '',
        dueDate:
            json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        status: json['status'] ?? 'pending',
        completedDate: json['completedDate'] != null
            ? DateTime.parse(json['completedDate'])
            : null,
        actualTimeSpent: json['actualTimeSpent'],
      );
  bool get isCompleted => status == 'full' || status == 'partial';
}

class Wisdom {
  final DateTime date;
  final String text;
  Wisdom({required this.date, required this.text});
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'text': text,
      };
  factory Wisdom.fromJson(Map<String, dynamic> json) =>
      Wisdom(date: DateTime.parse(json['date']), text: json['text']);
}

class Category {
  String name;
  List<String> notes;
  Category({required this.name, this.notes = const []});
  Map<String, dynamic> toJson() => {'name': name, 'notes': notes};
  factory Category.fromJson(Map<String, dynamic> json) =>
      Category(name: json['name'], notes: List<String>.from(json['notes']));
}

// ==================== STORAGE ====================
class Storage {
  static Future<void> saveAll() async {
    await _save(
      'habits',
      Global.habits.map((h) => jsonEncode(h.toJson())).toList(),
    );
    await _save(
      'tasks',
      Global.tasks.map((t) => jsonEncode(t.toJson())).toList(),
    );
    await _save(
      'reminders',
      Global.reminders.map((r) => jsonEncode(r.toJson())).toList(),
    );
    await _save(
      'wisdoms',
      Global.wisdoms.map((w) => jsonEncode(w.toJson())).toList(),
    );
    await _save(
      'categories',
      Global.categories.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  static Future<void> loadAll() async {
    Global.habits = await _load('habits', (j) => Habit.fromJson(j));
    Global.tasks = await _load('tasks', (j) => Task.fromJson(j));
    Global.reminders = await _load('reminders', (j) => Reminder.fromJson(j));
    Global.wisdoms = await _load('wisdoms', (j) => Wisdom.fromJson(j));
    Global.categories = await _load('categories', (j) => Category.fromJson(j));
  }

  static Future<void> _save(String key, List<String> data) async =>
      (await SharedPreferences.getInstance()).setStringList(key, data);
  static Future<List<T>> _load<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final list = (await SharedPreferences.getInstance()).getStringList(key);
    return list?.map((e) => fromJson(jsonDecode(e))).toList() ?? [];
  }
}

// ==================== HLAVNÍ MENU ====================
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Mini Kalendář',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: const MainMenu(),
      );
}

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            padding: const EdgeInsets.all(40),
            children: const [
              MenuButton("Evidence dne", Page2()),
              MenuButton("Habity / Úkoly / Připomínky", Page3()),
              MenuButton("Grafy", Page4()),
              MenuButton("Zápisky", Page5()),
            ],
          ),
        ),
      );
}

class MenuButton extends StatelessWidget {
  final String label;
  final Widget page;
  const MenuButton(this.label, this.page, {super.key});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
}

// ==================== PAGE 2: EVIDENCE DNE ====================
class Page2 extends StatefulWidget {
  const Page2({super.key});
  @override
  State<Page2> createState() => _Page2State();
}

class _Page2State extends State<Page2> {
  late final DateTime _currentDate = DateTime.now();
  static const String _lockedDaysKey = "locked_days";
  Set<String> _lockedDays = {};

  List<Task> _todayTasks = [];
  List<ReminderTask> _todayReminders = [];
  Wisdom? _dailyWisdom;

  @override
  void initState() {
    super.initState();
    _loadLockedDays();
    _loadTodayTasks();
    _loadTodayReminders();
    _loadDailyWisdom();
  }

  Future<void> _loadLockedDays() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? locked = prefs.getStringList(_lockedDaysKey);
    if (locked != null) setState(() => _lockedDays = locked.toSet());
  }

  Future<void> _saveLockedDays() async =>
      (await SharedPreferences.getInstance()).setStringList(
        _lockedDaysKey,
        _lockedDays.toList(),
      );

  Future<void> _loadTodayTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        "today_tasks_${_currentDate.year}_${_currentDate.month}_${_currentDate.day}";
    final List<String>? taskNames = prefs.getStringList(key);
    if (taskNames != null) {
      setState(() {
        _todayTasks = taskNames
            .map(
              (name) => Global.tasks.firstWhere(
                (t) => t.name == name,
                orElse: () => Task(name: name),
              ),
            )
            .where((t) => t.name.isNotEmpty)
            .toList();
      });
    }
  }

  Future<void> _saveTodayTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        "today_tasks_${_currentDate.year}_${_currentDate.month}_${_currentDate.day}";
    await prefs.setStringList(key, _todayTasks.map((t) => t.name).toList());
    // Uložit i actualTimeSpent do globálních úkolů
    for (var task in _todayTasks) {
      final globalIdx = Global.tasks.indexWhere((t) => t.name == task.name);
      if (globalIdx != -1) {
        Global.tasks[globalIdx].actualTimeSpent = task.actualTimeSpent;
      }
    }
    await Storage.saveAll();
  }

  Future<void> _loadTodayReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        "today_reminders_${_currentDate.year}_${_currentDate.month}_${_currentDate.day}";
    final List<String>? reminderData = prefs.getStringList(key);
    if (reminderData != null) {
      setState(() {
        _todayReminders = reminderData
            .map(
              (data) => ReminderTask.fromJson(
                jsonDecode(data) as Map<String, dynamic>,
              ),
            )
            .toList();
      });
    }
  }

  Future<void> _saveTodayReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        "today_reminders_${_currentDate.year}_${_currentDate.month}_${_currentDate.day}";
    await prefs.setStringList(
      key,
      _todayReminders.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  Future<void> _loadDailyWisdom() async {
    final existing = Global.wisdoms.firstWhere(
      (w) =>
          w.date.year == _currentDate.year &&
          w.date.month == _currentDate.month &&
          w.date.day == _currentDate.day,
      orElse: () => Wisdom(date: _currentDate, text: ''),
    );
    if (mounted) {
      setState(() => _dailyWisdom = existing.text.isEmpty ? null : existing);
    }
  }

  Future<void> _addDailyWisdom() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Denní moudro"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Napiš své moudro pro dnešek...",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Zrušit"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, controller.text.trim()),
            child: const Text("Uložit"),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final newWisdom = Wisdom(date: _currentDate, text: result);
      Global.wisdoms.removeWhere((w) => w.date == _currentDate);
      Global.wisdoms.add(newWisdom);
      await Storage.saveAll();
      _loadDailyWisdom();
      _showSnackBar("Moudro uloženo");
    }
  }

  bool get _isLocked => _lockedDays.contains(
        "${_currentDate.year}-${_currentDate.month}-${_currentDate.day}",
      );

  String get _dayName => [
        "Pondělí",
        "Úterý",
        "Středa",
        "Čtvrtek",
        "Pátek",
        "Sobota",
        "Neděle",
      ][_currentDate.weekday - 1];

  String _dayLetter(int w) => ["Po", "Út", "St", "Čt", "Pá", "So", "Ne"][w - 1];

  List<Habit> get _filteredHabits => Global.habits
      .where(
        (h) =>
            h.days.isEmpty || h.days.contains(_dayLetter(_currentDate.weekday)),
      )
      .toList();

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _getHabitStatus(Habit h) {
    for (var r in h.history) {
      if (_isSameDay(r.date, _currentDate)) return r.status;
    }
    return "nesplněno";
  }

  Future<void> _updateHabitStatus(int idx, String newStatus) async {
    if (_isLocked) {
      _showSnackBar("📅 Tento den je již evidovaný - nelze měnit");
      return;
    }
    final habit = _filteredHabits[idx];
    final originalIndex = Global.habits.indexOf(habit);
    if (originalIndex == -1) return;
    final newHistory =
        List<PerformanceRecord>.from(Global.habits[originalIndex].history)
          ..removeWhere((r) => _isSameDay(r.date, _currentDate))
          ..add(PerformanceRecord(date: _currentDate, status: newStatus));
    Global.habits[originalIndex].history = newHistory;
    await Storage.saveAll();
    if (mounted) setState(() {});
  }

  Future<void> _updateReminderStatus(
    ReminderTask reminder,
    String newStatus,
  ) async {
    if (_isLocked) {
      _showSnackBar("📅 Tento den je již evidovaný - nelze měnit");
      return;
    }
    final idx = _todayReminders.indexOf(reminder);
    if (idx != -1) {
      setState(() {
        _todayReminders[idx].status = newStatus;
        if (newStatus != 'pending') {
          _todayReminders[idx].completedDate = DateTime.now();
        }
      });
      await _saveTodayReminders();
    }
  }

  Future<void> _updateTaskStatus(Task task, String newStatus) async {
    if (_isLocked) {
      _showSnackBar("📅 Tento den je již evidovaný - nelze měnit");
      return;
    }
    final idx = _todayTasks.indexOf(task);
    if (idx != -1) {
      setState(() {
        _todayTasks[idx].status = newStatus;
        if (newStatus != 'pending') {
          _todayTasks[idx].completedDate = DateTime.now();
        }
      });
      await _saveTodayTasks();
      final globalIdx = Global.tasks.indexWhere((t) => t.name == task.name);
      if (globalIdx != -1) {
        Global.tasks[globalIdx].status = newStatus;
        if (newStatus != 'pending') {
          Global.tasks[globalIdx].completedDate = DateTime.now();
        }
        await Storage.saveAll();
      }
    }
  }

  Future<void> _updateTaskTimeSpent(Task task, int minutes) async {
    if (_isLocked) {
      _showSnackBar("📅 Tento den je již evidovaný - nelze měnit");
      return;
    }
    final idx = _todayTasks.indexOf(task);
    if (idx != -1) {
      setState(() {
        _todayTasks[idx].actualTimeSpent = minutes;
      });
      await _saveTodayTasks();
      _showSnackBar("Čas aktualizován");
    }
  }

  Future<void> _addTaskFromArchive(Task task) async {
    if (_isLocked) {
      _showSnackBar("📅 Tento den je již evidovaný - nelze měnit");
      return;
    }
    if (_todayTasks.any((t) => t.name == task.name)) {
      _showSnackBar("Úkol už je na dnešku");
      return;
    }
    final newTask = Task(
      name: task.name,
      description: task.description,
      durationMinutes: task.durationMinutes,
      fullDef: task.fullDef,
      partialDef: task.partialDef,
      dueDate: task.dueDate,
      status: 'pending',
      actualTimeSpent: null,
    );
    setState(() {
      _todayTasks.add(newTask);
    });
    await _saveTodayTasks();
    _showSnackBar("Úkol přidán na dnešek");
  }

  Future<void> _addReminderFromList(Reminder reminder) async {
    if (_isLocked) {
      _showSnackBar("📅 Tento den je již evidovaný - nelze měnit");
      return;
    }
    if (_todayReminders.any((r) => r.text == reminder.text)) {
      _showSnackBar("Připomínka už je na dnešku");
      return;
    }
    final newReminder = ReminderTask(
      text: reminder.text,
      date: reminder.date,
      status: 'pending',
    );
    setState(() {
      _todayReminders.add(newReminder);
    });
    await _saveTodayReminders();
    _showSnackBar("Připomínka přidána na dnešek");
  }

  Future<void> _addNewReminderDirectly(String text) async {
    if (_isLocked) {
      _showSnackBar("📅 Tento den je již evidovaný - nelze měnit");
      return;
    }
    if (text.trim().isEmpty) {
      _showSnackBar("Zadej text připomínky");
      return;
    }
    final newReminder = ReminderTask(
      text: text.trim(),
      date: _currentDate,
      status: 'pending',
    );
    setState(() {
      _todayReminders.add(newReminder);
    });
    await _saveTodayReminders();
    _showSnackBar("Připomínka přidána na dnešek");
  }

  Future<void> _removeTaskFromToday(Task task) async {
    if (_isLocked) {
      _showSnackBar("📅 Tento den je již evidovaný - nelze měnit");
      return;
    }
    setState(() {
      _todayTasks.remove(task);
    });
    await _saveTodayTasks();
    _showSnackBar("Úkol odstraněn z dnešku");
  }

  Future<void> _removeReminderFromToday(ReminderTask reminder) async {
    if (_isLocked) {
      _showSnackBar("📅 Tento den je již evidovaný - nelze měnit");
      return;
    }
    setState(() {
      _todayReminders.remove(reminder);
    });
    await _saveTodayReminders();
    _showSnackBar("Připomínka odstraněna z dnešku");
  }

  Future<void> _lockCurrentDay() async {
    if (_isLocked) {
      _showSnackBar("Tento den je již evidovaný");
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("📅 Evidovat den?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Po evidenci už nebude možné měnit stavy."),
            const SizedBox(height: 12),
            Text(
              "Datum: $_dayName ${_currentDate.day}.${_currentDate.month}.${_currentDate.year}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text("Zrušit"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Evidovat"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _lockedDays.add(
          "${_currentDate.year}-${_currentDate.month}-${_currentDate.day}",
        );
      });
      await _saveLockedDays();
      _showSnackBar("✅ Den byl úspěšně zaevidován");
    }
  }

  Future<void> _showAddDialog() async {
    final textController = TextEditingController();
    int selectedTab = 0;

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Přidat na dnešek"),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(
                              value: 0,
                              label: Text("Z existujících"),
                            ),
                            ButtonSegment(value: 1, label: Text("Nová")),
                          ],
                          selected: {selectedTab},
                          onSelectionChanged: (set) {
                            setDialogState(() {
                              selectedTab = set.first;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: selectedTab == 0
                        ? _buildExistingItemsTab(c, setDialogState)
                        : _buildNewItemTab(c, textController, setDialogState),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text("Zavřít"),
              ),
            ],
          );
        },
      ),
    );
    textController.dispose();
  }

  Widget _buildExistingItemsTab(
    BuildContext dialogContext,
    StateSetter setDialogState,
  ) {
    final availableTasks = Global.tasks
        .where((t) => !_todayTasks.any((tt) => tt.name == t.name))
        .toList();
    final today = DateTime(
      _currentDate.year,
      _currentDate.month,
      _currentDate.day,
    );
    final availableReminders = Global.reminders
        .where(
          (r) =>
              r.date.year == today.year &&
              r.date.month == today.month &&
              r.date.day == today.day &&
              !_todayReminders.any((tr) => tr.text == r.text),
        )
        .toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.task), text: "Úkoly"),
              Tab(icon: Icon(Icons.alarm), text: "Připomínky"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                availableTasks.isEmpty
                    ? const Center(child: Text("Žádné dostupné úkoly"))
                    : ListView.builder(
                        itemCount: availableTasks.length,
                        itemBuilder: (ctx, i) {
                          final t = availableTasks[i];
                          return ListTile(
                            title: Text(t.name),
                            subtitle: Text("⏱️ ${t.durationMinutes} min"),
                            trailing: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _addTaskFromArchive(t);
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text("Přidat"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                availableReminders.isEmpty
                    ? const Center(child: Text("Žádné dostupné připomínky"))
                    : ListView.builder(
                        itemCount: availableReminders.length,
                        itemBuilder: (ctx, i) {
                          final r = availableReminders[i];
                          return ListTile(
                            title: Text(r.text),
                            subtitle: Text(
                              "📅 ${r.date.day}.${r.date.month}.${r.date.year}",
                            ),
                            trailing: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _addReminderFromList(r);
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text("Přidat"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewItemTab(
    BuildContext dialogContext,
    TextEditingController controller,
    StateSetter setDialogState,
  ) {
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Text připomínky",
            border: OutlineInputBorder(),
            hintText: "Např. Koupit mléko",
          ),
          autofocus: true,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              Navigator.pop(dialogContext);
              _addNewReminderDirectly(controller.text);
            } else {
              ScaffoldMessenger.of(
                dialogContext,
              ).showSnackBar(const SnackBar(content: Text("Zadej text")));
            }
          },
          icon: const Icon(Icons.add),
          label: const Text("Přidat novou připomínku"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );

  Color _getHabitColor(String s) => s == "splněno"
      ? Colors.green
      : s == "částečně"
          ? Colors.orange
          : s == "zrušeno"
              ? Colors.red
              : Colors.grey;
  String _nextHabitStatus(String c) => c == "nesplněno"
      ? "splněno"
      : c == "splněno"
          ? "částečně"
          : c == "částečně"
              ? "zrušeno"
              : "nesplněno";
  String _nextTaskStatus(String c) => c == "pending"
      ? "full"
      : c == "full"
          ? "partial"
          : "pending";
  String _getStatusText(String s) => s == "full"
      ? "Splněno"
      : s == "partial"
          ? "Částečně"
          : "Nesplněno";
  Color _getStatusColor(String s) => s == "full"
      ? Colors.green
      : s == "partial"
          ? Colors.orange
          : Colors.grey;

  Future<void> _showTimeSpentDialog(Task task) async {
    final controller = TextEditingController(
      text: task.actualTimeSpent?.toString() ?? '',
    );
    final result = await showDialog<int>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text("Čas strávený u úkolu: ${task.name}"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Minuty",
            border: OutlineInputBorder(),
            suffixText: "min",
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Zrušit"),
          ),
          ElevatedButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text.trim());
              if (minutes != null) {
                Navigator.pop(c, minutes);
              } else {
                ScaffoldMessenger.of(c).showSnackBar(
                  const SnackBar(content: Text("Zadej platné číslo")),
                );
              }
            },
            child: const Text("Uložit"),
          ),
        ],
      ),
    );
    if (result != null) {
      await _updateTaskTimeSpent(task, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Evidence dne"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: "Evidovat den",
            onPressed: _lockCurrentDay,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: _isLocked ? Colors.green.shade50 : null,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _dayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isLocked) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "EVIDOVÁNO",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "${_currentDate.day}. ${_currentDate.month}. ${_currentDate.year}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isLocked)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "🔒 Uzamčeno - nelze měnit",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          _buildSectionHeader(
            Icons.fitness_center,
            Colors.blue,
            "HABITY",
            _filteredHabits.length,
          ),
          Expanded(
            flex: 2,
            child: _filteredHabits.isEmpty
                ? _buildEmptyState(
                    Icons.fitness_center,
                    "Žádné habity pro dnešek",
                  )
                : ListView.builder(
                    itemCount: _filteredHabits.length,
                    itemBuilder: (ctx, i) {
                      final h = _filteredHabits[i];
                      final cs = _getHabitStatus(h);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(
                            h.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isLocked ? Colors.grey : null,
                            ),
                          ),
                          subtitle: h.reason.isNotEmpty
                              ? Text(
                                  h.reason,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _isLocked ? Colors.grey : null,
                                  ),
                                )
                              : null,
                          trailing: GestureDetector(
                            onTap: _isLocked
                                ? null
                                : () => _updateHabitStatus(
                                      i,
                                      _nextHabitStatus(cs),
                                    ),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getHabitColor(
                                  cs,
                                ).withOpacity(_isLocked ? 0.5 : 1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.list, size: 20, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  "ÚKOLY A PŘIPOMÍNKY NA DNES",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                if (!_isLocked)
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.teal),
                    onPressed: _showAddDialog,
                    tooltip: "Přidat úkol nebo připomínku",
                  ),
                Text(
                  "${_todayTasks.length + _todayReminders.length}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: (_todayTasks.isEmpty && _todayReminders.isEmpty)
                ? _buildEmptyState(
                    Icons.inbox,
                    "Žádné úkoly ani připomínky\nKlikni na + pro přidání",
                  )
                : ListView.builder(
                    itemCount: _todayTasks.length + _todayReminders.length,
                    itemBuilder: (ctx, i) {
                      if (i < _todayTasks.length) {
                        final t = _todayTasks[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: _getStatusColor(
                                t.status,
                              ).withOpacity(0.2),
                              child: Icon(
                                t.status == 'full'
                                    ? Icons.check
                                    : t.status == 'partial'
                                        ? Icons.hourglass_empty
                                        : Icons.task,
                                size: 16,
                                color: _getStatusColor(t.status),
                              ),
                            ),
                            title: Text(
                              t.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: t.status != 'pending'
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "⏱️ ${t.durationMinutes} min plán | ⏲️ ${t.actualTimeSpent ?? 0} min skutečnost | ${_getStatusText(t.status)}",
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!_isLocked)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.timer,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    onPressed: () => _showTimeSpentDialog(t),
                                    tooltip: "Nastavit čas",
                                  ),
                                if (!_isLocked)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () => _removeTaskFromToday(t),
                                    tooltip: "Odstranit",
                                  ),
                                GestureDetector(
                                  onTap: _isLocked
                                      ? null
                                      : () => _updateTaskStatus(
                                            t,
                                            _nextTaskStatus(t.status),
                                          ),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(t.status),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      t.status == 'full'
                                          ? Icons.check
                                          : t.status == 'partial'
                                              ? Icons.hourglass_empty
                                              : Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        final r = _todayReminders[i - _todayTasks.length];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: _getStatusColor(
                                r.status,
                              ).withOpacity(0.2),
                              child: Icon(
                                r.status == 'full'
                                    ? Icons.check
                                    : r.status == 'partial'
                                        ? Icons.hourglass_empty
                                        : Icons.alarm,
                                size: 16,
                                color: _getStatusColor(r.status),
                              ),
                            ),
                            title: Text(
                              r.text,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: r.status != 'pending'
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              "📅 Připomínka | ${_getStatusText(r.status)}",
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!_isLocked)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _removeReminderFromToday(r),
                                    tooltip: "Odstranit",
                                  ),
                                GestureDetector(
                                  onTap: _isLocked
                                      ? null
                                      : () => _updateReminderStatus(
                                            r,
                                            _nextTaskStatus(r.status),
                                          ),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(r.status),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      r.status == 'full'
                                          ? Icons.check
                                          : r.status == 'partial'
                                              ? Icons.hourglass_empty
                                              : Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.psychology, size: 20, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  "DENNÍ MOUDRO",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                if (!_isLocked && _dailyWisdom == null)
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.purple),
                    onPressed: _addDailyWisdom,
                    tooltip: "Přidat moudro",
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple.shade50,
            child: _dailyWisdom != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dailyWisdom!.text,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Přidáno: ${_fmtDate(_dailyWisdom!.date)}",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    "Žádné moudro pro dnešek. Klikni na + pro přidání.",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) => "${d.day}.${d.month}.${d.year}";

  Widget _buildSectionHeader(
    IconData icon,
    Color color,
    String title,
    int count,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            Text("$count", style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );

  Widget _buildEmptyState(IconData icon, String text) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

class ReminderTask {
  String text;
  DateTime date;
  String status;
  DateTime? completedDate;

  ReminderTask({
    required this.text,
    required this.date,
    this.status = 'pending',
    this.completedDate,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'date': date.toIso8601String(),
        'status': status,
        'completedDate': completedDate?.toIso8601String(),
      };

  factory ReminderTask.fromJson(Map<String, dynamic> json) => ReminderTask(
        text: json['text'],
        date: DateTime.parse(json['date']),
        status: json['status'] ?? 'pending',
        completedDate: json['completedDate'] != null
            ? DateTime.parse(json['completedDate'])
            : null,
      );
}

// ==================== PAGE 3: HABITY / ÚKOLY / PŘIPOMÍNKY ====================
class Page3 extends StatefulWidget {
  const Page3({super.key});
  @override
  State<Page3> createState() => _Page3State();
}

class _Page3State extends State<Page3> with SingleTickerProviderStateMixin {
  late TabController _tc;
  final List<String> weekDays = ["Po", "Út", "St", "Čt", "Pá", "So", "Ne"];

  final _habitName = TextEditingController(),
      _habitReason = TextEditingController(),
      _habitFull = TextEditingController(),
      _habitPart = TextEditingController();
  List<bool> _selectedDays = List.filled(7, false);
  bool _showHabitForm = false;

  final _taskName = TextEditingController(),
      _taskDesc = TextEditingController(),
      _taskDuration = TextEditingController(),
      _taskFull = TextEditingController(),
      _taskPart = TextEditingController();
  DateTime? _taskDueDate;
  bool _showTaskForm = false;

  final _reminderText = TextEditingController();
  DateTime? _reminderDate;
  bool _showReminderForm = false;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tc.dispose();
    _habitName.dispose();
    _habitReason.dispose();
    _habitFull.dispose();
    _habitPart.dispose();
    _taskName.dispose();
    _taskDesc.dispose();
    _taskDuration.dispose();
    _taskFull.dispose();
    _taskPart.dispose();
    _reminderText.dispose();
    super.dispose();
  }

  void _showSnackBar(String m) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), duration: const Duration(seconds: 1)),
      );

  Future<void> _addHabit() async {
    if (_habitName.text.trim().isEmpty) {
      _showSnackBar("Zadej název");
      return;
    }
    List<String> days = [];
    for (int i = 0; i < weekDays.length; i++) {
      if (_selectedDays[i]) days.add(weekDays[i]);
    }
    Global.habits.add(
      Habit(
        name: _habitName.text.trim(),
        reason: _habitReason.text.trim(),
        fullDef: _habitFull.text.trim(),
        partialDef: _habitPart.text.trim(),
        days: days,
      ),
    );
    _habitName.clear();
    _habitReason.clear();
    _habitFull.clear();
    _habitPart.clear();
    _selectedDays = List.filled(7, false);
    _showHabitForm = false;
    await Storage.saveAll();
    setState(() {});
    _showSnackBar("Habit přidán");
  }

  Future<void> _deleteHabit(int i) async {
    if (await _showDeleteDialog("habit", Global.habits[i].name)) {
      setState(() => Global.habits.removeAt(i));
      await Storage.saveAll();
      _showSnackBar("Smazáno");
    }
  }

  void _editHabit(int i) {
    final h = Global.habits[i];
    _habitName.text = h.name;
    _habitReason.text = h.reason;
    _habitFull.text = h.fullDef;
    _habitPart.text = h.partialDef;
    for (int j = 0; j < weekDays.length; j++) {
      _selectedDays[j] = h.days.contains(weekDays[j]);
    }
    Global.habits.removeAt(i);
    _showHabitForm = true;
    setState(() {});
  }

  Future<void> _addTask() async {
    if (_taskName.text.trim().isEmpty) {
      _showSnackBar("Zadej název");
      return;
    }
    Global.tasks.add(
      Task(
        name: _taskName.text.trim(),
        description: _taskDesc.text.trim(),
        durationMinutes: int.tryParse(_taskDuration.text.trim()) ?? 0,
        fullDef: _taskFull.text.trim(),
        partialDef: _taskPart.text.trim(),
        dueDate: _taskDueDate,
      ),
    );
    _taskName.clear();
    _taskDesc.clear();
    _taskDuration.clear();
    _taskFull.clear();
    _taskPart.clear();
    _taskDueDate = null;
    _showTaskForm = false;
    await Storage.saveAll();
    setState(() {});
    _showSnackBar("Úkol přidán");
  }

  Future<void> _deleteTask(int i) async {
    if (await _showDeleteDialog("úkol", Global.tasks[i].name)) {
      setState(() => Global.tasks.removeAt(i));
      await Storage.saveAll();
      _showSnackBar("Smazáno");
    }
  }

  void _editTask(int i) {
    final t = Global.tasks[i];
    _taskName.text = t.name;
    _taskDesc.text = t.description;
    _taskDuration.text = t.durationMinutes.toString();
    _taskFull.text = t.fullDef;
    _taskPart.text = t.partialDef;
    _taskDueDate = t.dueDate;
    Global.tasks.removeAt(i);
    _showTaskForm = true;
    setState(() {});
  }

  Future<void> _addReminder() async {
    if (_reminderText.text.trim().isEmpty) {
      _showSnackBar("Zadej text");
      return;
    }
    if (_reminderDate == null) {
      _showSnackBar("Vyber datum");
      return;
    }
    Global.reminders.add(
      Reminder(text: _reminderText.text.trim(), date: _reminderDate!),
    );
    _reminderText.clear();
    _reminderDate = null;
    _showReminderForm = false;
    await Storage.saveAll();
    setState(() {});
    _showSnackBar("Připomínka přidána");
  }

  Future<void> _deleteReminder(int i) async {
    if (await _showDeleteDialog("připomínku", Global.reminders[i].text)) {
      setState(() => Global.reminders.removeAt(i));
      await Storage.saveAll();
      _showSnackBar("Smazáno");
    }
  }

  void _editReminder(int i) {
    final r = Global.reminders[i];
    _reminderText.text = r.text;
    _reminderDate = r.date;
    Global.reminders.removeAt(i);
    _showReminderForm = true;
    setState(() {});
  }

  Future<bool> _showDeleteDialog(String typ, String nazev) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text("Smazat $typ?"),
          content: Text("\"$nazev\""),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text("Zrušit"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Smazat"),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _pickDueDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _taskDueDate = d);
  }

  Future<void> _pickReminderDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (d != null) setState(() => _reminderDate = d);
  }

  String _formatDate(DateTime? d) =>
      d == null ? "Bez termínu" : "${d.day}.${d.month}.${d.year}";

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Habity / Úkoly / Připomínky"),
          bottom: TabBar(
            controller: _tc,
            tabs: const [
              Tab(icon: Icon(Icons.fitness_center), text: "HABITY"),
              Tab(icon: Icon(Icons.task), text: "ÚKOLY"),
              Tab(icon: Icon(Icons.alarm), text: "PŘIPOMÍNKY"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tc,
          children: [_buildHabitsTab(), _buildTasksTab(), _buildRemindersTab()],
        ),
      );

  Widget _buildHabitsTab() => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _showHabitForm = !_showHabitForm),
              icon: Icon(_showHabitForm ? Icons.close : Icons.add),
              label: Text(_showHabitForm ? "ZRUŠIT" : "PŘIDAT HABIT"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor: _showHabitForm ? Colors.red : Colors.green,
              ),
            ),
          ),
          if (_showHabitForm) _buildHabitForm(),
          Expanded(
            child: Global.habits.isEmpty
                ? _buildEmpty(Icons.fitness_center, "Žádné habity")
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: Global.habits.length,
                    itemBuilder: (_, i) => _buildHabitCard(i),
                  ),
          ),
        ],
      );

  Widget _buildHabitForm() => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              "Přidat habit",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _habitName,
              decoration: const InputDecoration(labelText: "Název *"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _habitReason,
              decoration: const InputDecoration(labelText: "Důvod"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _habitFull,
              decoration: const InputDecoration(labelText: "Definice SPLNĚNÍ"),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _habitPart,
              decoration:
                  const InputDecoration(labelText: "Definice ČÁSTEČNÉHO"),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            const Text(
              "Dny v týdnu:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(
                weekDays.length,
                (i) => FilterChip(
                  label: Text(weekDays[i]),
                  selected: _selectedDays[i],
                  onSelected: (s) => setState(() => _selectedDays[i] = s),
                  selectedColor: Colors.blue.shade300,
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addHabit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("ULOŽIT"),
              ),
            ),
          ],
        ),
      );

  Widget _buildHabitCard(int i) {
    final h = Global.habits[i];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.fitness_center, color: Colors.blue),
        ),
        title: Text(
          h.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Dny: ${h.days.isEmpty ? 'Každý den' : h.days.join(', ')}",
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _editHabit(i),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteHabit(i),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (h.reason.isNotEmpty) ...[
                  const Text(
                    "DŮVOD:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(h.reason),
                  const SizedBox(height: 8),
                ],
                const Text(
                  "DEFINICE SPLNĚNÍ:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(h.fullDef.isEmpty ? "není definováno" : h.fullDef),
                const SizedBox(height: 8),
                const Text(
                  "DEFINICE ČÁSTEČNÉHO:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(h.partialDef.isEmpty ? "není definováno" : h.partialDef),
                const SizedBox(height: 8),
                const Text(
                  "HISTORIE:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("${h.history.length} záznamů"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksTab() => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _showTaskForm = !_showTaskForm),
              icon: Icon(_showTaskForm ? Icons.close : Icons.add),
              label: Text(_showTaskForm ? "ZRUŠIT" : "PŘIDAT ÚKOL"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor: _showTaskForm ? Colors.red : Colors.green,
              ),
            ),
          ),
          if (_showTaskForm) _buildTaskForm(),
          Expanded(
            child: Global.tasks.isEmpty
                ? _buildEmpty(Icons.archive, "Žádné úkoly")
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: Global.tasks.length,
                    itemBuilder: (_, i) => _buildTaskCard(i),
                  ),
          ),
        ],
      );

  Widget _buildTaskForm() => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              "Přidat úkol",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _taskName,
              decoration: const InputDecoration(labelText: "Název *"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _taskDesc,
              decoration: const InputDecoration(labelText: "Popis"),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _taskDuration,
              decoration: const InputDecoration(
                labelText: "Délka (minuty)",
                suffixText: "min",
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _taskFull,
              decoration: const InputDecoration(labelText: "Definice SPLNĚNÍ"),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _taskPart,
              decoration:
                  const InputDecoration(labelText: "Definice ČÁSTEČNÉHO"),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text("Termín: ${_formatDate(_taskDueDate)}")),
                ElevatedButton.icon(
                  onPressed: _pickDueDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text("Vybrat"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addTask,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("ULOŽIT"),
              ),
            ),
          ],
        ),
      );

  Widget _buildTaskCard(int i) {
    final t = Global.tasks[i];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: const Icon(Icons.task, color: Colors.orange),
        ),
        title: Text(
          t.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "⏱️ ${t.durationMinutes} min | ${_formatDate(t.dueDate)}",
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _editTask(i),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteTask(i),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (t.description.isNotEmpty) ...[
                  const Text(
                    "POPIS:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(t.description),
                  const SizedBox(height: 8),
                ],
                const Text(
                  "DEFINICE SPLNĚNÍ:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(t.fullDef.isEmpty ? "není definováno" : t.fullDef),
                const SizedBox(height: 8),
                const Text(
                  "DEFINICE ČÁSTEČNÉHO:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(t.partialDef.isEmpty ? "není definováno" : t.partialDef),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersTab() => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: () =>
                  setState(() => _showReminderForm = !_showReminderForm),
              icon: Icon(_showReminderForm ? Icons.close : Icons.add),
              label: Text(_showReminderForm ? "ZRUŠIT" : "PŘIDAT PŘIPOMÍNKU"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor: _showReminderForm ? Colors.red : Colors.teal,
              ),
            ),
          ),
          if (_showReminderForm) _buildReminderForm(),
          Expanded(
            child: Global.reminders.isEmpty
                ? _buildEmpty(Icons.alarm_off, "Žádné připomínky")
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: Global.reminders.length,
                    itemBuilder: (_, i) => _buildReminderCard(i),
                  ),
          ),
        ],
      );

  Widget _buildReminderForm() => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              "Přidat připomínku",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reminderText,
              decoration: const InputDecoration(
                labelText: "Text připomínky",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _reminderDate == null
                        ? "📅 Datum nevybráno"
                        : "📅 ${_formatDate(_reminderDate)}",
                    style: TextStyle(
                      color: _reminderDate == null ? Colors.grey : Colors.teal,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickReminderDate,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text("Vybrat"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addReminder,
                  icon: const Icon(Icons.add),
                  label: const Text("Přidat"),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildReminderCard(int i) {
    final r = Global.reminders[i];
    final isPassed = r.date.isBefore(DateTime.now());
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isPassed ? Colors.red.shade100 : Colors.teal.shade100,
          child: Icon(
            isPassed ? Icons.warning : Icons.alarm,
            color: isPassed ? Colors.red : Colors.teal,
          ),
        ),
        title: Text(
          r.text,
          style: TextStyle(
            decoration: isPassed ? TextDecoration.lineThrough : null,
            color: isPassed ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          "📅 ${_formatDate(r.date)}${isPassed ? " (prošlé)" : ""}",
          style: TextStyle(
            color: isPassed ? Colors.red.shade300 : Colors.grey.shade600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _editReminder(i),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteReminder(i),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(IconData icon, String text) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(text),
          ],
        ),
      );
}

// ==================== PAGE 4: GRAFY (PŘEPRACOVANÁ) ====================
class Page4 extends StatefulWidget {
  const Page4({super.key});
  @override
  State<Page4> createState() => _Page4State();
}

class _Page4State extends State<Page4> {
  String _period = "týden";
  String _chartType = "celkový"; // "celkový" nebo "jednotlivé" nebo "všechny"
  final Set<int> _selectedHabits = {};
  final Set<int> _selectedTasks = {};

  // Pro posouvání kalendáře
  DateTime _calendarOffset = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Storage.loadAll();
    if (mounted) setState(() {});
  }

  List<Habit> get _habits =>
      _selectedHabits.map((i) => Global.habits[i]).toList();
  List<Task> get _tasks => _selectedTasks.map((i) => Global.tasks[i]).toList();

  bool get _hasSelection => _habits.isNotEmpty || _tasks.isNotEmpty;

  // Získání denních skóre pro všechny vybrané položky dohromady
  Map<DateTime, double> get _dailyScores {
    Map<DateTime, double> scores = {};

    for (var habit in _habits) {
      for (var record in habit.history) {
        final date = DateTime(
          record.date.year,
          record.date.month,
          record.date.day,
        );
        final value = record.status == "splněno"
            ? 1.0
            : record.status == "částečně"
                ? 0.5
                : 0.0;
        scores[date] = (scores[date] ?? 0) + value;
      }
    }

    for (var task in _tasks) {
      if (task.completedDate != null && task.status != 'pending') {
        final date = DateTime(
          task.completedDate!.year,
          task.completedDate!.month,
          task.completedDate!.day,
        );
        final value = task.status == "full" ? 1.0 : 0.5;
        scores[date] = (scores[date] ?? 0) + value;
      }
    }

    // Normalizace na procenta (maximální možné skóre = počet vybraných položek)
    final maxScore = _habits.length + _tasks.length;
    if (maxScore > 0) {
      for (var date in scores.keys) {
        scores[date] = (scores[date]! / maxScore) * 100;
      }
    }

    return scores;
  }

  // Získání denních skóre pro VŠECHNY aktivity (habity + úkoly, které byly ten den zadány)
  Map<DateTime, double> get _allActivitiesScores {
    Map<DateTime, double> scores = {};

    // Všechny habity
    for (var habit in Global.habits) {
      for (var record in habit.history) {
        final date = DateTime(
          record.date.year,
          record.date.month,
          record.date.day,
        );
        final value = record.status == "splněno"
            ? 1.0
            : record.status == "částečně"
                ? 0.5
                : 0.0;
        scores[date] = (scores[date] ?? 0) + value;
      }
    }

    // Pouze úkoly, které mají completedDate a nejsou pending (byly ten den zadány a splněny)
    for (var task in Global.tasks) {
      if (task.completedDate != null && task.status != 'pending') {
        final date = DateTime(
          task.completedDate!.year,
          task.completedDate!.month,
          task.completedDate!.day,
        );
        final value = task.status == "full" ? 1.0 : 0.5;
        scores[date] = (scores[date] ?? 0) + value;
      }
    }

    // Normalizace: max skóre = počet habitů + počet UNIKÁTNÍCH úkolů splněných ten den?
    // Lepší je normalizovat na počet habitů + počet úkolů splněných ten den? To by bylo nestabilní.
    // Pro jednoduchost normalizujeme na (počet habitů + 1), ale to není ideální.
    // Lepší: nechat skóre jako součet bodů (každý habit/úkol max 1) a zobrazovat to jako absolutní hodnoty.
    // Ale pro procenta potřebujeme max. Použijeme max možný počet bodů = počet habitů + max počet úkolů za den (což je těžké).
    // Změníme logiku: v grafu "všechny" budeme zobrazovat průměrnou úspěšnost na jednu aktivitu.
    // Takže pro každý den vydělíme počtem aktivit, které ten den byly hodnoceny.
    for (var date in scores.keys) {
      int activitiesCount = 0;
      // Spočítáme, kolik habitů mělo ten den záznam
      for (var habit in Global.habits) {
        if (habit.history.any((r) => _isSameDay(r.date, date))) {
          activitiesCount++;
        }
      }
      // Spočítáme, kolik úkolů bylo ten den splněno
      for (var task in Global.tasks) {
        if (task.completedDate != null &&
            _isSameDay(task.completedDate!, date)) {
          activitiesCount++;
        }
      }
      if (activitiesCount > 0) {
        scores[date] = (scores[date]! / activitiesCount) * 100;
      } else {
        scores[date] = 0;
      }
    }

    return scores;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Získání denních skóre pro jednu konkrétní položku
  Map<DateTime, double> _getItemScores(dynamic item) {
    Map<DateTime, double> scores = {};

    if (item is Habit) {
      for (var record in item.history) {
        final date = DateTime(
          record.date.year,
          record.date.month,
          record.date.day,
        );
        final value = record.status == "splněno"
            ? 100.0
            : record.status == "částečně"
                ? 50.0
                : 0.0;
        scores[date] = value;
      }
    } else if (item is Task) {
      if (item.completedDate != null && item.status != 'pending') {
        final date = DateTime(
          item.completedDate!.year,
          item.completedDate!.month,
          item.completedDate!.day,
        );
        final value = item.status == "full" ? 100.0 : 50.0;
        scores[date] = value;
      }
    }

    return scores;
  }

  // Filtrování podle období
  List<DateTime> get _dateRange {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    DateTime start;

    if (_period == "týden") {
      start = end.subtract(const Duration(days: 7));
    } else if (_period == "měsíc") {
      start = end.subtract(const Duration(days: 30));
    } else {
      start = DateTime(2000, 1, 1);
    }

    return [start, end];
  }

  Map<DateTime, double> get _filteredScores {
    final range = _dateRange;
    final scoresToUse =
        _chartType == "všechny" ? _allActivitiesScores : _dailyScores;
    return Map.fromEntries(
      scoresToUse.entries.where(
        (entry) =>
            entry.key.isAfter(range[0]) &&
            entry.key.isBefore(range[1].add(const Duration(days: 1))),
      ),
    );
  }

  List<MapEntry<DateTime, double>> get _sortedFilteredScores {
    final entries = _filteredScores.entries.toList();
    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  double get _averageSuccess {
    if (_sortedFilteredScores.isEmpty) return 0;
    double sum = 0;
    for (var entry in _sortedFilteredScores) {
      sum += entry.value;
    }
    return sum / _sortedFilteredScores.length;
  }

  // Data pro kalendář (5 týdnů = 35 dní)
  List<Map<String, dynamic>> get _calendarData {
    final List<Map<String, dynamic>> weeks = [];
    final startDate = DateTime(
      _calendarOffset.year,
      _calendarOffset.month,
      _calendarOffset.day,
    );
    final firstDay = DateTime(startDate.year, startDate.month, 1);
    final startWeekday = firstDay.weekday % 7;

    DateTime current = firstDay.subtract(Duration(days: startWeekday));

    for (int w = 0; w < 5; w++) {
      List<Map<String, dynamic>> week = [];
      for (int d = 0; d < 7; d++) {
        final date = current;
        double score;
        if (_chartType == "všechny") {
          score =
              _allActivitiesScores[DateTime(date.year, date.month, date.day)] ??
                  0;
        } else {
          score = _dailyScores[DateTime(date.year, date.month, date.day)] ?? 0;
        }
        week.add({
          'date': date,
          'day': date.day,
          'month': date.month,
          'year': date.year,
          'score': score,
          'isCurrentMonth': date.month == _calendarOffset.month,
        });
        current = current.add(const Duration(days: 1));
      }
      weeks.add({'week': week, 'weekNum': w});
    }

    return weeks;
  }

  void _previousMonth() {
    setState(() {
      _calendarOffset = DateTime(
        _calendarOffset.year,
        _calendarOffset.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _calendarOffset = DateTime(
        _calendarOffset.year,
        _calendarOffset.month + 1,
        1,
      );
    });
  }

  void _goToToday() {
    setState(() {
      _calendarOffset = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar:
            AppBar(title: const Text("Grafy"), backgroundColor: Colors.blue),
        body: Column(
          children: [
            _buildPeriodSelector(),
            const Divider(),
            if (_chartType != "všechny") _buildItemSelectors(),
            const Divider(),
            if (_chartType != "všechny" &&
                !_hasSelection &&
                _chartType != "všechny")
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        "Vyber alespoň jeden habit nebo úkol",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Celkem k dispozici: ${Global.habits.length + Global.tasks.length} položek",
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Celková úspěšnost
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.blue.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _chartType == "všechny"
                                      ? "Celková úspěšnost všech aktivit"
                                      : "Celková úspěšnost",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _chartType == "všechny"
                                      ? "habity + splněné úkoly"
                                      : "vybraných aktivit",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${_averageSuccess.toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: _getColor(_averageSuccess),
                                  ),
                                ),
                                Text(
                                  "z ${_sortedFilteredScores.length} dnů",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // KALENDÁŘ 5x7
                      _buildCalendar(),
                      const SizedBox(height: 24),

                      // VOLBA TYPU GRAFU
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _chartTypeBtn("celkový", "Vybrané aktivity"),
                          const SizedBox(width: 12),
                          _chartTypeBtn("jednotlivé", "Detail aktivit"),
                          const SizedBox(width: 12),
                          _chartTypeBtn("všechny", "Všechny aktivity"),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // GRAFY
                      if (_chartType == "celkový")
                        _buildOverallChart()
                      else if (_chartType == "jednotlivé")
                        _buildIndividualCharts()
                      else
                        _buildOverallChart(allActivities: true),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _chartTypeBtn(String type, String label) => GestureDetector(
        onTap: () => setState(() => _chartType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _chartType == type ? Colors.blue : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: _chartType == type ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

  Widget _buildCalendar() {
    final calendarData = _calendarData;
    final monthNames = [
      "Leden",
      "Únor",
      "Březen",
      "Duben",
      "Květen",
      "Červen",
      "Červenec",
      "Srpen",
      "Září",
      "Říjen",
      "Listopad",
      "Prosinec",
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Hlavička kalendáře s měsícem
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                ),
                Text(
                  "${monthNames[_calendarOffset.month - 1]} ${_calendarOffset.year}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.today),
                      onPressed: _goToToday,
                      tooltip: "Dnes",
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Dny v týdnu
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ["Po", "Út", "St", "Čt", "Pá", "So", "Ne"]
                  .map(
                    (day) => Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Týdny
          ...calendarData.map((weekData) {
            final week = weekData['week'] as List;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: week.map((day) {
                final isToday = day['year'] == DateTime.now().year &&
                    day['month'] == DateTime.now().month &&
                    day['day'] == DateTime.now().day;
                final score = day['score'] as double;

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: day['isCurrentMonth']
                          ? _getCalendarColor(score).withOpacity(0.3)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: Colors.blue, width: 2)
                          : null,
                    ),
                    child: Tooltip(
                      message:
                          "${day['day']}.${day['month']}.${day['year']}\nÚspěšnost: ${score.toStringAsFixed(0)}%",
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Text(
                              "${day['day']}",
                              style: TextStyle(
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: day['isCurrentMonth']
                                    ? Colors.black
                                    : Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 30,
                              height: 4,
                              decoration: BoxDecoration(
                                color: _getColor(score),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }),

          // Legenda
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legendItem(Colors.green, "75-100%"),
                _legendItem(Colors.lightGreen, "50-75%"),
                _legendItem(Colors.orange, "25-50%"),
                _legendItem(Colors.red, "0-25%"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text) => Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 10)),
        ],
      );

  Color _getCalendarColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.lightGreen;
    if (score >= 25) return Colors.orange;
    return Colors.red;
  }

  Widget _buildOverallChart({bool allActivities = false}) {
    final scores = _sortedFilteredScores;
    if (scores.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text("Žádná data pro vybrané období")),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Text(
              allActivities
                  ? "Vývoj úspěšnosti všech aktivit"
                  : "Celkový vývoj úspěšnosti",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          SizedBox(
            height: 250,
            child: _LineChart(
              data: scores
                  .map((e) => _ChartData(date: e.key, value: e.value))
                  .toList(),
              color: Colors.blue,
              title: allActivities ? "Všechny aktivity" : "Celková úspěšnost",
            ),
          ),
          const SizedBox(height: 16),
          _buildDataTable(scores),
        ],
      ),
    );
  }

  Widget _buildIndividualCharts() {
    final List<dynamic> allItems = [..._habits, ..._tasks];
    final List<Widget> charts = [];

    for (var item in allItems) {
      final scores = _getItemScores(item);
      final filtered = scores.entries
          .where(
            (e) =>
                e.key.isAfter(_dateRange[0]) &&
                e.key.isBefore(_dateRange[1].add(const Duration(days: 1))),
          )
          .toList();
      filtered.sort((a, b) => a.key.compareTo(b.key));

      if (filtered.isNotEmpty) {
        final name = item is Habit ? item.name : (item as Task).name;
        final icon = item is Habit ? Icons.fitness_center : Icons.task;
        final color = item is Habit ? Colors.blue : Colors.green;

        charts.add(
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: color),
                      const SizedBox(width: 8),
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: color,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "${(filtered.map((e) => e.value).reduce((a, b) => a + b) / filtered.length).toStringAsFixed(0)}%",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: _LineChart(
                    data: filtered
                        .map((e) => _ChartData(date: e.key, value: e.value))
                        .toList(),
                    color: color,
                    title: name,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (charts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text("Žádná data pro vybrané položky")),
      );
    }

    return Column(children: charts);
  }

  Widget _buildDataTable(List<MapEntry<DateTime, double>> scores) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade50,
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    "Datum",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Úspěšnost",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 150,
            child: ListView.builder(
              itemCount: scores.reversed.toList().length,
              itemBuilder: (ctx, i) {
                final entry = scores.reversed.toList()[i];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${entry.key.day}.${entry.key.month}.${entry.key.year}",
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 80,
                              height: 8,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: FractionallySizedBox(
                                widthFactor: entry.value / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _getColor(entry.value),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              "${entry.value.toStringAsFixed(0)}%",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getColor(entry.value),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() => Container(
        padding: const EdgeInsets.all(12),
        color: Colors.grey.shade50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _periodBtn("týden", "Týden"),
            _periodBtn("měsíc", "Měsíc"),
            _periodBtn("all_time", "Celkem"),
          ],
        ),
      );

  Widget _periodBtn(String p, String l) => GestureDetector(
        onTap: () => setState(() => _period = p),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: _period == p ? Colors.blue : Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: _period == p
                ? []
                : [BoxShadow(color: Colors.grey.shade300, blurRadius: 2)],
          ),
          child: Text(
            l,
            style: TextStyle(
              color: _period == p ? Colors.white : Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

  Widget _buildItemSelectors() => Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (Global.habits.isNotEmpty)
              _buildSelectorRow(
                "HABITY",
                Global.habits,
                _selectedHabits,
                Icons.fitness_center,
                Colors.blue,
              ),
            if (Global.tasks.isNotEmpty) const SizedBox(height: 12),
            if (Global.tasks.isNotEmpty)
              _buildSelectorRow(
                "ÚKOLY",
                Global.tasks,
                _selectedTasks,
                Icons.task,
                Colors.green,
              ),
          ],
        ),
      );

  Widget _buildSelectorRow<T>(
    String title,
    List<T> items,
    Set<int> selected,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                const Spacer(),
                Text(
                  "${selected.length}/${items.length}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: items.asMap().entries.map((entry) {
                final name = items is List<Habit>
                    ? (entry.value as Habit).name
                    : (entry.value as Task).name;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(name, style: const TextStyle(fontSize: 12)),
                    selected: selected.contains(entry.key),
                    onSelected: (checked) {
                      setState(() {
                        if (checked) {
                          selected.add(entry.key);
                        } else {
                          selected.remove(entry.key);
                        }
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: color.withOpacity(0.2),
                    checkmarkColor: color,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(double percent) {
    if (percent >= 75) return Colors.green;
    if (percent >= 50) return Colors.lightGreen;
    if (percent >= 25) return Colors.orange;
    return Colors.red;
  }
}

// Třída pro data grafu
class _ChartData {
  final DateTime date;
  final double value;
  _ChartData({required this.date, required this.value});
}

// Spojnicový graf
class _LineChart extends StatelessWidget {
  final List<_ChartData> data;
  final Color color;
  final String title;

  const _LineChart({
    required this.data,
    required this.color,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text("Žádná data"));
    }

    double maxY = 100;
    double minY = 0;
    double width = data.length * 60.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: width > 400 ? width : 400,
        height: 250,
        child: CustomPaint(
          painter: _LineChartPainter(
            data: data,
            maxY: maxY,
            minY: minY,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<_ChartData> data;
  final double maxY;
  final double minY;
  final Color color;

  _LineChartPainter({
    required this.data,
    required this.maxY,
    required this.minY,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double leftPadding = 45;
    final double rightPadding = 20;
    final double topPadding = 20;
    final double bottomPadding = 35;
    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    final double stepX =
        data.length > 1 ? chartWidth / (data.length - 1) : chartWidth;
    final double rangeY = maxY - minY;

    // Y osa
    final axisPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, size.height - bottomPadding),
      axisPaint,
    );

    // X osa
    canvas.drawLine(
      Offset(leftPadding, size.height - bottomPadding),
      Offset(size.width - rightPadding, size.height - bottomPadding),
      axisPaint,
    );

    // Y hodnoty a mřížka
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i <= 4; i++) {
      double value = minY + (rangeY * i / 4);
      double y = size.height - bottomPadding - (value / maxY * chartHeight);
      textPainter.text = TextSpan(
        text: "${value.toStringAsFixed(0)}%",
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftPadding - 35, y - 6));

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        Paint()
          ..color = Colors.grey.shade200
          ..strokeWidth = 0.5,
      );
    }

    // X hodnoty
    for (int i = 0; i < data.length; i++) {
      double x = leftPadding + (i * stepX);
      textPainter.text = TextSpan(
        text: "${data[i].date.day}.${data[i].date.month}",
        style: const TextStyle(fontSize: 9, color: Colors.grey),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - 15, size.height - bottomPadding + 5),
      );
    }

    // Body a spojnice
    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      double x = leftPadding + (i * stepX);
      double y =
          size.height - bottomPadding - (data[i].value / maxY * chartHeight);
      points.add(Offset(x, y));

      // Bod
      final pointPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 5, pointPaint);

      // Obrys bodu
      final outlinePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(x, y), 5, outlinePaint);
    }

    // Spojnice
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }

    // Výplň pod spojnicí
    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    Path fillPath = Path();
    if (points.isNotEmpty) {
      fillPath.moveTo(points[0].dx, size.height - bottomPadding);
      for (var point in points) {
        fillPath.lineTo(point.dx, point.dy);
      }
      fillPath.lineTo(points.last.dx, size.height - bottomPadding);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==================== PAGE 5: ZÁPISKY ====================
class Page5 extends StatefulWidget {
  const Page5({super.key});
  @override
  State<Page5> createState() => _Page5State();
}

class _Page5State extends State<Page5> {
  final _catCtrl = TextEditingController(), _noteCtrl = TextEditingController();
  String? _selectedCat;

  void _addCat() {
    if (_catCtrl.text.trim().isEmpty) return;
    Global.categories.add(Category(name: _catCtrl.text.trim()));
    _catCtrl.clear();
    Storage.saveAll();
    setState(() {});
  }

  void _delCat(int i) {
    final name = Global.categories[i].name;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Smazat kategorii?"),
        content: Text(
          "Smazat \"$name\" i s ${Global.categories[i].notes.length} zápisy?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Zrušit"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                Global.categories.removeAt(i);
                if (_selectedCat == name) _selectedCat = null;
              });
              Storage.saveAll();
              Navigator.pop(c);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Smazat"),
          ),
        ],
      ),
    );
  }

  void _addNote() {
    if (_selectedCat == null || _noteCtrl.text.trim().isEmpty) return;
    final idx = Global.categories.indexWhere((c) => c.name == _selectedCat);
    if (idx != -1) {
      setState(() => Global.categories[idx].notes.add(_noteCtrl.text.trim()));
      _noteCtrl.clear();
      Storage.saveAll();
    }
  }

  void _delNote(int ci, int ni) {
    setState(() => Global.categories[ci].notes.removeAt(ni));
    Storage.saveAll();
  }

  void _delWisdom(int i) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Smazat moudro?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Zrušit"),
          ),
          TextButton(
            onPressed: () {
              setState(() => Global.wisdoms.removeAt(i));
              Storage.saveAll();
              Navigator.pop(c);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Smazat"),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) => "${d.day}. ${d.month}. ${d.year}";

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Zápisky"),
            backgroundColor: Colors.purple,
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.category), text: "Kategorie"),
                Tab(icon: Icon(Icons.psychology), text: "Moudra"),
              ],
            ),
          ),
          body: TabBarView(children: [_buildCats(), _buildWisdoms()]),
        ),
      );

  Widget _buildCats() => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _catCtrl,
                    decoration: const InputDecoration(
                      hintText: "Nová kategorie...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addCat,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: Global.categories.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category, size: 64, color: Colors.grey),
                        Text("Žádné kategorie"),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: Global.categories.length,
                    itemBuilder: (_, i) {
                      final c = Global.categories[i];
                      final exp = _selectedCat == c.name;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(
                                c.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text("${c.notes.length} zápisků"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _delCat(i),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      exp
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                    ),
                                    onPressed: () => setState(
                                      () => _selectedCat = exp ? null : c.name,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (exp) ...[
                              const Divider(),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _noteCtrl,
                                            decoration: const InputDecoration(
                                              hintText: "Nový zápisek...",
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: _addNote,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.purple,
                                          ),
                                          child: const Icon(Icons.add),
                                        ),
                                      ],
                                    ),
                                    ...c.notes.asMap().entries.map(
                                          (e) => Card(
                                            color: Colors.grey.shade50,
                                            margin: const EdgeInsets.only(
                                                bottom: 8),
                                            child: ListTile(
                                              title: Text(e.value),
                                              trailing: IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 20,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () =>
                                                    _delNote(i, e.key),
                                              ),
                                            ),
                                          ),
                                        ),
                                    if (c.notes.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text("Žádné zápisky"),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      );

  Widget _buildWisdoms() {
    final sorted = List<Wisdom>.from(Global.wisdoms)
      ..sort((a, b) => b.date.compareTo(a.date));
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.purple.shade50,
          child: const Row(
            children: [
              Icon(Icons.psychology, color: Colors.purple),
              SizedBox(width: 8),
              Expanded(child: Text("Denní moudra se řadí od nejnovějších")),
            ],
          ),
        ),
        Expanded(
          child: sorted.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.psychology, size: 64, color: Colors.grey),
                      Text("Žádná moudra"),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sorted.length,
                  itemBuilder: (_, i) {
                    final w = sorted[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.purple,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _fmtDate(w.date),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _delWisdom(
                                    Global.wisdoms.indexWhere(
                                      (ww) => ww.date == w.date,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(w.text, style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
