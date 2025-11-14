import 'package:flutter/cupertino.dart';
import 'package:pinco_mind_app/app/features/board/task_editor_screen.dart';
import 'package:pinco_mind_app/app/models/task.dart';
import 'package:pinco_mind_app/app/task_controller.dart';
import 'package:pinco_mind_app/app/theme_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TaskController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = TaskScope.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.isInitialized) {
        _controller.init();
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

  List<Task> _filterTasks() {
    final DateTime now = DateTime.now();
    final DateTime start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 2));
    final DateTime end = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 2));
    final List<Task> tasks =
        _controller.tasks.where((Task task) {
          final DateTime? due = task.dueDate;
          if (due == null) {
            return false;
          }
          final DateTime date = DateTime(due.year, due.month, due.day);
          return !date.isBefore(start) && !date.isAfter(end);
        }).toList()..sort((Task a, Task b) {
          final DateTime aDue = a.dueDate!;
          final DateTime bDue = b.dueDate!;
          return aDue.compareTo(bDue);
        });
    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    final EdgeInsets mediaPadding = MediaQuery.of(context).padding;
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppPalette.darkSurfaceElevated.withOpacity(0.7),
        border: null,
        middle: Text('Dashboard', style: theme.textTheme.navTitleTextStyle),
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
            top: -120,
            left: -60,
            child: _GlowSphere(size: 260, color: AppPalette.darkPrimary),
          ),
          Positioned(
            bottom: -140,
            right: -40,
            child: _GlowSphere(size: 220, color: AppPalette.darkPrimarySoft),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? _) {
              if (!_controller.isInitialized || _controller.isLoading) {
                return const Center(child: CupertinoActivityIndicator());
              }
              final List<Task> tasks = _filterTasks();
              if (tasks.isEmpty) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: mediaPadding.left,
                    right: mediaPadding.right,
                    bottom: mediaPadding.bottom + 96,
                  ),
                  child: _EmptyState(onCreate: _createTask),
                );
              }
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  20 + mediaPadding.left,
                  16 + mediaPadding.top + 40,
                  20 + mediaPadding.right,
                  120 + mediaPadding.bottom,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final Task task = tasks[index];
                  return _TaskTile(task: task, onTap: () => _editTask(task));
                },
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(height: 12),
                itemCount: tasks.length,
              );
            },
          ),
          Positioned(
            right: 20,
            bottom: 24 + mediaPadding.bottom,
            child: _QuickAddButton(onPressed: _createTask),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.onTap});

  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    final TextStyle base = theme.textTheme.textStyle;
    final DateTime due = task.dueDate!.toLocal();
    final String date = _formatDate(due);
    final String relative = _formatRelative(due);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: AppPalette.cardGradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.45),
            width: 1.1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppPalette.darkPrimary.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              task.title.isEmpty ? 'Untitled task' : task.title,
              style: base.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: theme.primaryContrastingColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              task.description.isEmpty ? 'Без описания' : task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: base.copyWith(
                fontSize: 14,
                height: 1.4,
                color: theme.primaryContrastingColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Icon(
                  CupertinoIcons.calendar,
                  size: 16,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  date,
                  style: base.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.primaryContrastingColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  relative,
                  style: base.copyWith(
                    fontSize: 13,
                    color: theme.primaryContrastingColor.withValues(
                      alpha: 0.75,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatRelative(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime target = DateTime(date.year, date.month, date.day);
    final int delta = target.difference(today).inDays;
    if (delta == 0) {
      return 'Сегодня';
    }
    if (delta > 0) {
      return delta == 1 ? 'Завтра' : 'Через $delta д';
    }
    final int past = delta.abs();
    return past == 1 ? 'Вчера' : '$past д назад';
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
                  CupertinoIcons.chart_bar_alt_fill,
                  size: 54,
                  color: theme.primaryColor,
                ),
                const SizedBox(height: 18),
                Text(
                  'Нет задач с ближайшим дедлайном',
                  textAlign: TextAlign.center,
                  style: base.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryContrastingColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Добавьте задачу, чтобы контролировать сроки и успевать вовремя.',
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
                  child: const Text('Быстро добавить'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppPalette.cardGradient,
        boxShadow: AppPalette.glowShadow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.48)),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        borderRadius: BorderRadius.circular(28),
        color: CupertinoColors.transparent,
        pressedOpacity: 0.75,
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(CupertinoIcons.add, color: theme.primaryContrastingColor),
            const SizedBox(width: 8),
            Text(
              'New Task',
              style: theme.textTheme.textStyle.copyWith(
                color: theme.primaryContrastingColor,
                fontWeight: FontWeight.w600,
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
