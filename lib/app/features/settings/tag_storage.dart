import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:pinco_mind_app/app/models/tag.dart';

class TagStorage {
  static const String _tagsKey = 'settings.tags';

  Future<List<Tag>> readTags() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_tagsKey);
    if (raw == null || raw.isEmpty) {
      return <Tag>[];
    }
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Tag.fromJson)
          .toList();
    } on FormatException {
      return <Tag>[];
    }
  }

  Future<void> writeTags(List<Tag> tags) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> serialized = tags
        .map((Tag tag) => tag.toJson())
        .toList();
    await prefs.setString(_tagsKey, jsonEncode(serialized));
  }
}
