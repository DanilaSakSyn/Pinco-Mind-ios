import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:pinco_mind_app/app/models/task.dart';

class TaskStorage {
  static const String _tasksKey = 'board.tasks';

  Future<List<Task>> readTasks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_tasksKey);
    if (raw == null || raw.isEmpty) {
      return <Task>[];
    }
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Task.fromJson)
          .toList();
    } on FormatException {
      return <Task>[];
    }
  }

  Future<void> writeTasks(List<Task> tasks) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> serialized = tasks
        .map((Task task) => task.toJson())
        .toList();
    await prefs.setString(_tasksKey, jsonEncode(serialized));
  }
}
