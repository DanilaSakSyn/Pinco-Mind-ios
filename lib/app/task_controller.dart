import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pinco_mind_app/app/features/board/task_storage.dart';
import 'package:pinco_mind_app/app/models/task.dart';

class TaskController extends ChangeNotifier {
  TaskController({TaskStorage? storage}) : _storage = storage ?? TaskStorage();

  final TaskStorage _storage;

  List<Task> _tasks = <Task>[];
  bool _isInitialized = false;
  bool _isLoading = false;

  List<Task> get tasks => List<Task>.unmodifiable(_tasks);
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    if (_isInitialized || _isLoading) {
      return;
    }
    await _loadTasks();
  }

  Future<void> refresh() async {
    await _loadTasks(force: true);
  }

  Future<void> upsertTask(Task task) async {
    final int index = _tasks.indexWhere(
      (Task existing) => existing.id == task.id,
    );
    final List<Task> next = List<Task>.from(_tasks);
    if (index == -1) {
      next.add(task);
    } else {
      next[index] = task;
    }
    _tasks = next;
    await _storage.writeTasks(_tasks);
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    final List<Task> next =
        _tasks.where((Task task) => task.id != taskId).toList();
    if (next.length == _tasks.length) {
      return;
    }
    _tasks = next;
    await _storage.writeTasks(_tasks);
    notifyListeners();
  }

  Future<void> _loadTasks({bool force = false}) async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    notifyListeners();
    final List<Task> stored = await _storage.readTasks();
    if (stored.isEmpty) {
      _tasks = _seedTasks();
      await _storage.writeTasks(_tasks);
    } else {
      _tasks = stored;
    }
    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  List<Task> _seedTasks() {
    final DateTime now = DateTime.now();
    return <Task>[
      // Task(
      //   id: 'task_${now.microsecondsSinceEpoch - 3}',
      //   title: 'Review sprint scope',
      //   description:
      //       'Align backlog items with the quarterly roadmap before kickoff.',
      //   createdAt: now.subtract(const Duration(days: 2)),
      //   updatedAt: now.subtract(const Duration(days: 1, hours: 4)),
      //   lastModifiedAt: now.subtract(const Duration(days: 1, hours: 4)),
      //   tagIds: const <String>[],
      //   dueDate: now.add(const Duration(days: 5)),
      // ),
      // Task(
      //   id: 'task_${now.microsecondsSinceEpoch - 2}',
      //   title: 'Design task board',
      //   description:
      //       'Sketch updated columns and hand-off to design system team.',
      //   createdAt: now.subtract(const Duration(days: 1, hours: 6)),
      //   updatedAt: now.subtract(const Duration(hours: 6)),
      //   lastModifiedAt: now.subtract(const Duration(hours: 6)),
      //   tagIds: const <String>[],
      //   dueDate: now.add(const Duration(days: 2)),
      // ),
      // Task(
      //   id: 'task_${now.microsecondsSinceEpoch - 1}',
      //   title: 'Prepare release notes',
      //   description:
      //       'Summarize recent fixes and new beta features for stakeholders.',
      //   createdAt: now.subtract(const Duration(days: 3)),
      //   updatedAt: now.subtract(const Duration(days: 1)),
      //   lastModifiedAt: now.subtract(const Duration(days: 1)),
      //   tagIds: const <String>[],
      //   dueDate: now.subtract(const Duration(days: 1)),
      // ),
    ];
  }
}

class TaskScope extends InheritedNotifier<TaskController> {
  const TaskScope({required super.notifier, required super.child, super.key});

  static TaskController of(BuildContext context) {
    final TaskScope? scope =
        context.dependOnInheritedWidgetOfExactType<TaskScope>();
    assert(scope != null, 'TaskScope not found in context');
    return scope!.notifier!;
  }
}
