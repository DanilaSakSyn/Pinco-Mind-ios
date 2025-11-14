import 'package:flutter/cupertino.dart';
import 'package:pinco_mind_app/app/tag_controller.dart';
import 'package:pinco_mind_app/app/models/tag.dart';
import 'package:pinco_mind_app/app/models/task.dart';
import 'package:pinco_mind_app/app/theme_controller.dart';

class TaskEditorScreen extends StatefulWidget {
  const TaskEditorScreen({super.key, required this.task});

  final Task task;

  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TagController _tagController;
  late List<String> _selectedTagIds;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description,
    );
    _selectedTagIds = List<String>.from(widget.task.tagIds);
    _dueDate = widget.task.dueDate;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tagController = TagScope.of(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSave => _titleController.text.trim().isNotEmpty;

  void _toggleTag(String tagId) {
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds = _selectedTagIds
            .where((String id) => id != tagId)
            .toList();
      } else {
        _selectedTagIds = <String>[..._selectedTagIds, tagId];
      }
    });
  }

  Future<void> _pickDueDate() async {
    final DateTime initial = _dueDate ?? DateTime.now();
    DateTime tempSelection = initial;
    final DateTime? picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (BuildContext context) {
        final CupertinoThemeData theme = CupertinoTheme.of(context);
        return Container(
          height: 320,
          color: theme.scaffoldBackgroundColor,
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () => Navigator.of(context).pop(tempSelection),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initial,
                  minimumYear: DateTime.now().year - 5,
                  maximumYear: DateTime.now().year + 10,
                  onDateTimeChanged: (DateTime value) {
                    tempSelection = DateTime(
                      value.year,
                      value.month,
                      value.day,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _clearDueDate() {
    setState(() => _dueDate = null);
  }

  String _formatDueDate(DateTime date) {
    final DateTime local = date.toLocal();
    final String month = local.month.toString().padLeft(2, '0');
    final String day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  Future<void> _handleSave() async {
    if (!_canSave) {
      return;
    }
    final Task updatedTask = widget.task.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      updatedAt: DateTime.now(),
      tagIds: _sanitizeTagSelection(),
      dueDate: _dueDate,
      removeDueDate: _dueDate == null,
    );
    Navigator.of(context).pop(updatedTask);
  }

  List<String> _sanitizeTagSelection() {
    final Set<String> available = _tagController.tags
        .map((Tag tag) => tag.id)
        .toSet();
    return _selectedTagIds
        .where((String id) => available.contains(id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNew = widget.task.isEmpty;
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    final Color accent = theme.primaryColor;
    final BoxDecoration fieldDecoration = BoxDecoration(
      gradient: AppPalette.cardGradient,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: accent.withValues(alpha: 0.42), width: 1.1),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: accent.withValues(alpha: 0.16),
          blurRadius: 22,
          offset: const Offset(0, 12),
        ),
      ],
    );

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppPalette.darkSurfaceElevated.withOpacity(0.7),
        border: null,
        middle: Text(isNew ? 'New Task' : 'Edit Task'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _canSave ? _handleSave : null,
          child: Text('Save', style: theme.textTheme.navTitleTextStyle),
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: AppPalette.darkBackgroundGradient,
              ),
            ),
          ),
          Positioned(
            top: -160,
            right: -80,
            child: _GlowSphere(size: 260, color: AppPalette.darkPrimary),
          ),
          Positioned(
            bottom: -140,
            left: -60,
            child: _GlowSphere(size: 220, color: AppPalette.darkPrimarySoft),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: <Widget>[
                _EditorLabel(text: 'Title'),
                CupertinoTextField(
                  controller: _titleController,
                  placeholder: 'Enter task title',
                  cursorColor: theme.primaryColor,
                  textCapitalization: TextCapitalization.sentences,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: fieldDecoration,
                  style: theme.textTheme.textStyle.copyWith(
                    color: theme.primaryContrastingColor,
                  ),
                  placeholderStyle: theme.textTheme.textStyle.copyWith(
                    color: theme.primaryContrastingColor.withValues(
                      alpha: 0.55,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                _EditorLabel(text: 'Description'),
                CupertinoTextField(
                  controller: _descriptionController,
                  placeholder: 'Describe the task',
                  cursorColor: theme.primaryColor,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 5,
                  minLines: 4,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: fieldDecoration,
                  style: theme.textTheme.textStyle.copyWith(
                    color: theme.primaryContrastingColor,
                  ),
                  placeholderStyle: theme.textTheme.textStyle.copyWith(
                    color: theme.primaryContrastingColor.withValues(
                      alpha: 0.55,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _EditorLabel(text: 'Due Date'),
                Container(
                  decoration: fieldDecoration,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          alignment: Alignment.centerLeft,
                          onPressed: _pickDueDate,
                          child: Text(
                            _dueDate != null
                                ? _formatDueDate(_dueDate!)
                                : 'Select a date',
                            style: theme.textTheme.textStyle.copyWith(
                              fontSize: 15,
                              color: theme.primaryContrastingColor,
                            ),
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onPressed: _dueDate != null ? _clearDueDate : null,
                        child: Text(
                          'Clear',
                          style: theme.textTheme.textStyle.copyWith(
                            color: _dueDate != null
                                ? CupertinoColors.systemRed
                                : theme.primaryContrastingColor.withValues(
                                    alpha: 0.4,
                                  ),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _EditorLabel(text: 'Tags'),
                AnimatedBuilder(
                  animation: _tagController,
                  builder: (BuildContext context, Widget? _) {
                    if (!_tagController.isInitialized ||
                        _tagController.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CupertinoActivityIndicator()),
                      );
                    }
                    final List<Tag> tags = _tagController.tags;
                    if (tags.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        decoration: fieldDecoration,
                        child: Text(
                          'Create tags in Settings to assign them here.',
                          style: theme.textTheme.textStyle.copyWith(
                            fontSize: 13,
                            color: theme.primaryContrastingColor.withValues(
                              alpha: 0.65,
                            ),
                          ),
                        ),
                      );
                    }
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: tags.map((Tag tag) {
                        final bool selected = _selectedTagIds.contains(tag.id);
                        return _SelectableTagChip(
                          tag: tag,
                          selected: selected,
                          onTap: () => _toggleTag(tag.id),
                        );
                      }).toList(),
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
}

class _EditorLabel extends StatelessWidget {
  const _EditorLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.textStyle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.primaryContrastingColor,
        ),
      ),
    );
  }
}

class _SelectableTagChip extends StatelessWidget {
  const _SelectableTagChip({
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  final Tag tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    final Color baseColor = tag.color;
    final Color background = selected
        ? baseColor
        : baseColor.withValues(alpha: 0.18);
    final Color borderColor = baseColor.withValues(
      alpha: selected ? 0.7 : 0.35,
    );
    final Color textColor = selected
        ? CupertinoColors.white
        : theme.primaryContrastingColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (selected)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  size: 16,
                  color: CupertinoColors.white,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: baseColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Text(
              tag.name,
              style: theme.textTheme.textStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowSphere extends StatelessWidget {
  const _GlowSphere({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[color.withOpacity(0.45), color.withOpacity(0)],
        ),
      ),
    );
  }
}
