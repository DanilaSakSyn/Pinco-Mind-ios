import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pinco_mind_app/app/features/settings/tag_storage.dart';
import 'package:pinco_mind_app/app/models/tag.dart';

class TagController extends ChangeNotifier {
  TagController({TagStorage? storage}) : _storage = storage ?? TagStorage();

  final TagStorage _storage;

  List<Tag> _tags = <Tag>[];
  bool _isInitialized = false;
  bool _isLoading = false;

  List<Tag> get tags => List<Tag>.unmodifiable(_tags);
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    if (_isInitialized || _isLoading) {
      return;
    }
    await _loadTags();
  }

  Future<void> refresh() async {
    await _loadTags(force: true);
  }

  Future<Tag> createTag({required String name, required Color color}) async {
    final Tag tag = Tag.create(name: name, color: color);
    _tags = <Tag>[..._tags, tag];
    await _storage.writeTags(_tags);
    notifyListeners();
    return tag;
  }

  Future<void> deleteTag(String tagId) async {
    final List<Tag> next = _tags.where((Tag tag) => tag.id != tagId).toList();
    if (next.length == _tags.length) {
      return;
    }
    _tags = next;
    await _storage.writeTags(_tags);
    notifyListeners();
  }

  Future<void> updateTag(String tagId, {String? name, Color? color}) async {
    final int index = _tags.indexWhere((Tag tag) => tag.id == tagId);
    if (index == -1) {
      return;
    }
    final Tag current = _tags[index];
    final Tag updated = current.copyWith(name: name, color: color);
    final List<Tag> next = List<Tag>.from(_tags);
    next[index] = updated;
    _tags = next;
    await _storage.writeTags(_tags);
    notifyListeners();
  }

  Future<void> _loadTags({bool force = false}) async {
    if (_isLoading || (_isInitialized && !force)) {
      return;
    }
    _isLoading = true;
    notifyListeners();
    final List<Tag> stored = await _storage.readTags();
    _tags = stored;
    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }
}

class TagScope extends InheritedNotifier<TagController> {
  const TagScope({required super.notifier, required super.child, super.key});

  static TagController of(BuildContext context) {
    final TagScope? scope = context
        .dependOnInheritedWidgetOfExactType<TagScope>();
    assert(scope != null, 'TagScope not found in context');
    return scope!.notifier!;
  }
}
