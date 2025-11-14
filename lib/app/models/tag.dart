import 'package:flutter/cupertino.dart';

@immutable
class Tag {
  const Tag({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  factory Tag.create({required String name, required Color color}) {
    final DateTime now = DateTime.now();
    return Tag(
      id: 'tag_${now.microsecondsSinceEpoch}',
      name: name,
      color: color,
      createdAt: now,
    );
  }

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id:
          json['id'] as String? ??
          'tag_${DateTime.now().microsecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Untitled',
      color: Color((json['color'] as int?) ?? const Color(0xFF424242).value),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  final String id;
  final String name;
  final Color color;
  final DateTime createdAt;

  Tag copyWith({String? name, Color? color}) {
    return Tag(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'color': color.value,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      final DateTime? parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return DateTime.now();
  }
}
