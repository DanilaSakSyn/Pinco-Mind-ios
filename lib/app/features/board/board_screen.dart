import 'package:flutter/cupertino.dart';
import '../../tag_controller.dart';
import '../../task_controller.dart';
import 'task_editor_screen.dart';
import '../../models/tag.dart';
import '../../models/task.dart';
import '../../theme_controller.dart';
import '../../widgets/tag_badge.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  late TaskController _controller;
  late TagController _tagController;
  String? _selectedTagId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = TaskScope.of(context);
    _tagController = TagScope.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.isInitialized) {
        _controller.init();
      }
      if (!_tagController.isInitialized) {
        _tagController.init();
      }
    });
  }

  Future<void> _createTask() async {
    final Task draft = Task.newDraft();
    final Task? savedTask = await Navigator.of(context).push<Task>(
      CupertinoPageRoute<Task>(
        builder: (BuildContext context) => TaskEditorScreen(task: draft),
      ),
    );
    if (savedTask == null || savedTask.isEmpty) {
      return;
    }
    await _controller.upsertTask(savedTask);
  }

  Future<void> _editTask(Task task) async {
    final Task? updatedTask = await Navigator.of(context).push<Task>(
      CupertinoPageRoute<Task>(
        builder: (BuildContext context) => TaskEditorScreen(task: task),
      ),
    );
    if (updatedTask == null) {
      return;
    }
    await _controller.upsertTask(updatedTask);
  }

  Future<void> _deleteTask(Task task) async {
    await _controller.deleteTask(task.id);
  }

  void _onTagSelected(String? tagId) {
    if (_selectedTagId == tagId) {
      return;
    }
    setState(() {
      _selectedTagId = tagId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppPalette.darkSurfaceElevated.withOpacity(0.7),
        border: null,
        middle: Text('Board', style: theme.textTheme.navTitleTextStyle),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _createTask,
          child: Icon(CupertinoIcons.add, color: theme.primaryColor),
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
            right: -60,
            child: _GlowSphere(size: 280, color: AppPalette.darkPrimary),
          ),
          Positioned(
            bottom: -120,
            left: -40,
            child: _GlowSphere(size: 220, color: AppPalette.darkPrimarySoft),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[
                _controller,
                _tagController,
              ]),
              builder: (BuildContext context, Widget? _) {
                if (!_controller.isInitialized || _controller.isLoading) {
                  return const Center(child: CupertinoActivityIndicator());
                }
                final List<Task> tasks = _controller.tasks;
                if (tasks.isEmpty) {
                  return _EmptyState(onCreate: _createTask);
                }
                final List<Tag> availableTags = _tagController.tags;
                final List<Task> filteredTasks = _selectedTagId == null
                    ? tasks
                    : tasks
                        .where(
                          (Task task) => task.tagIds.contains(_selectedTagId),
                        )
                        .toList();
                final List<Task> orderedTasks = filteredTasks.toList()
                  ..sort(
                    (Task a, Task b) =>
                        b.lastModifiedAt.compareTo(a.lastModifiedAt),
                  );
                final Map<String, Tag> tagIndex = <String, Tag>{
                  for (final Tag tag in availableTags) tag.id: tag,
                };
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: <Widget>[
                    if (availableTags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _TagFilterBar(
                          tags: availableTags,
                          selectedTagId: _selectedTagId,
                          onTagSelected: _onTagSelected,
                        ),
                      ),
                    _StatusSection(
                      tasks: orderedTasks,
                      onTaskTap: _editTask,
                      onTaskDelete: _deleteTask,
                      tagIndex: tagIndex,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TagFilterBar extends StatelessWidget {
  const _TagFilterBar({
    required this.tags,
    required this.selectedTagId,
    required this.onTagSelected,
  });

  final List<Tag> tags;
  final String? selectedTagId;
  final ValueChanged<String?> onTagSelected;

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);

    final Widget allChip = _TagFilterChip(
      label: 'All',
      isSelected: selectedTagId == null,
      color: theme.primaryColor,
      showDot: false,
      onTap: () => onTagSelected(null),
    );
    final List<Widget> children = <Widget>[allChip];
    for (final Tag tag in tags) {
      children
        ..add(const SizedBox(width: 12))
        ..add(
          _TagFilterChip(
            label: tag.name,
            isSelected: tag.id == selectedTagId,
            color: tag.color,
            showDot: true,
            onTap: () => onTagSelected(tag.id),
          ),
        );
    }

    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(children: children),
      ),
    );
  }
}

class _TagFilterChip extends StatelessWidget {
  const _TagFilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.showDot,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    final Color background = isSelected
        ? color.withValues(alpha: 0.22)
        : theme.primaryContrastingColor.withValues(alpha: 0.08);
    final Color borderColor = isSelected
        ? color.withValues(alpha: 0.6)
        : theme.primaryContrastingColor.withValues(alpha: 0.18);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.1),
          boxShadow: isSelected
              ? <BoxShadow>[
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ]
              : <BoxShadow>[],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (showDot)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            Text(
              label,
              style: theme.textTheme.textStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.primaryContrastingColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({
    required this.tasks,
    required this.onTaskTap,
    required this.onTaskDelete,
    required this.tagIndex,
  });

  final List<Task> tasks;
  final ValueChanged<Task> onTaskTap;
  final Future<void> Function(Task task) onTaskDelete;
  final Map<String, Tag> tagIndex;

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    final Color accent = theme.primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 16),
          if (tasks.isEmpty)
            _EmptyColumn(accent: accent)
          else
            ...tasks.map((Task task) {
              final List<Tag> tags = task.tagIds
                  .map((String id) => tagIndex[id])
                  .whereType<Tag>()
                  .toList();
              return _TaskCard(
                task: task,
                accent: accent,
                onTap: () => onTaskTap(task),
                onDelete: () => onTaskDelete(task),
                tags: tags,
              );
            }),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.accent,
    required this.onTap,
    required this.onDelete,
    required this.tags,
  });

  final Task task;
  final Color accent;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;
  final List<Tag> tags;

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    final TextStyle base = theme.textTheme.textStyle;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Dismissible(
          key: ValueKey<String>(task.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onDelete(),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: CupertinoColors.systemRed,
            child: const Icon(
              CupertinoIcons.delete_simple,
              color: CupertinoColors.white,
            ),
          ),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppPalette.cardGradient,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: accent.withValues(alpha: 0.45),
                  width: 1.1,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: accent.withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    task.title,
                    style: base.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryContrastingColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: base.copyWith(
                      fontSize: 14,
                      height: 1.4,
                      color: theme.primaryContrastingColor.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                  if (task.dueDate != null) ...<Widget>[
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        const Icon(CupertinoIcons.calendar_today, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          _formatDue(task.dueDate!),
                          style: base.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryContrastingColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (tags.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags
                          .map((Tag tag) => TagBadge(tag: tag, dense: true))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDue(DateTime date) {
    final DateTime local = date.toLocal();
    final String month = local.month.toString().padLeft(2, '0');
    final String day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}

class _EmptyColumn extends StatelessWidget {
  const _EmptyColumn({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: AppPalette.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        'No tasks here yet. Add one with the + button.',
        style: theme.textTheme.textStyle.copyWith(
          fontSize: 14,
          color: theme.primaryContrastingColor.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    final TextStyle base = theme.textTheme.textStyle;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppPalette.cardGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.4),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.18),
                blurRadius: 26,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  CupertinoIcons.square_list_fill,
                  size: 54,
                  color: theme.primaryColor,
                ),
                const SizedBox(height: 18),
                Text(
                  'Create your first task',
                  style: base.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryContrastingColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Start by adding a task. You can update its details or status at any time.',
                  textAlign: TextAlign.center,
                  style: base.copyWith(
                    fontSize: 15,
                    height: 1.45,
                    color: theme.primaryContrastingColor.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
                CupertinoButton.filled(
                  onPressed: onCreate,
                  child: const Text('New Task'),
                ),
              ],
            ),
          ),
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
