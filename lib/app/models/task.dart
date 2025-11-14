import 'package:flutter/foundation.dart';

@immutable
class Task {
  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required DateTime updatedAt,
    required List<String> tagIds,
    DateTime? dueDate,
    DateTime? lastModifiedAt,
  }) : updatedAt = updatedAt,
       lastModifiedAt = lastModifiedAt ?? updatedAt,
       tagIds = List<String>.unmodifiable(tagIds),
       dueDate = dueDate != null
           ? DateTime.fromMillisecondsSinceEpoch(
               dueDate.millisecondsSinceEpoch,
               isUtc: dueDate.isUtc,
             )
           : null;

  factory Task.newDraft() {
    final DateTime now = DateTime.now();
    return Task(
      id: 'task_${now.microsecondsSinceEpoch}',
      title: '',
      description: '',
      createdAt: now,
      updatedAt: now,
      tagIds: const <String>[],
      dueDate: null,
    );
  }

  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastModifiedAt;
  final List<String> tagIds;
  final DateTime? dueDate;

  bool get isEmpty => title.trim().isEmpty && description.trim().isEmpty;

  Task copyWith({
    String? title,
    String? description,
    DateTime? updatedAt,
    DateTime? lastModifiedAt,
    List<String>? tagIds,
    DateTime? dueDate,
    bool removeDueDate = false,
  }) {
    final DateTime? overrideTimestamp = lastModifiedAt ?? updatedAt;
    final DateTime nextTimestamp = overrideTimestamp ?? this.updatedAt;
    final List<String> resolvedTagIds = tagIds != null
        ? List<String>.from(tagIds)
        : List<String>.from(this.tagIds);
    final DateTime? resolvedDueDate = removeDueDate
        ? null
        : (dueDate ?? this.dueDate);
    final DateTime? clonedDueDate = resolvedDueDate != null
        ? DateTime.fromMillisecondsSinceEpoch(
            resolvedDueDate.millisecondsSinceEpoch,
            isUtc: resolvedDueDate.isUtc,
          )
        : null;
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: nextTimestamp,
      lastModifiedAt: overrideTimestamp ?? this.lastModifiedAt,
      tagIds: resolvedTagIds,
      dueDate: clonedDueDate,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastModifiedAt': lastModifiedAt.toIso8601String(),
      'tagIds': tagIds,
      'dueDate': dueDate?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final DateTime now = DateTime.now();
    final DateTime parsedUpdatedAt = _parseDate(json['updatedAt'], now);
    final DateTime parsedLastModifiedAt = _parseDate(
      json['lastModifiedAt'],
      parsedUpdatedAt,
    );
    return Task(
      id: json['id'] as String? ?? 'task_${now.microsecondsSinceEpoch}',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: _parseDate(json['createdAt'], now),
      updatedAt: parsedUpdatedAt,
      lastModifiedAt: parsedLastModifiedAt,
      tagIds: _parseTagIds(json['tagIds']),
      dueDate: _parseOptionalDate(json['dueDate']),
    );
  }

  static DateTime _parseDate(dynamic value, DateTime fallback) {
    if (value is String) {
      final DateTime? parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return fallback;
  }

  static List<String> _parseTagIds(dynamic raw) {
    if (raw is List) {
      return raw
          .where((dynamic value) => value is String)
          .cast<String>()
          .toList();
    }
    return <String>[];
  }

  static DateTime? _parseOptionalDate(dynamic raw) {
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }
}
