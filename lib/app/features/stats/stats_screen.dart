import 'package:flutter/cupertino.dart';
import 'package:pinco_mind_app/app/models/tag.dart';
import 'package:pinco_mind_app/app/models/task.dart';
import 'package:pinco_mind_app/app/tag_controller.dart';
import 'package:pinco_mind_app/app/task_controller.dart';
import 'package:pinco_mind_app/app/theme_controller.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late TaskController _taskController;
  late TagController _tagController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _taskController = TaskScope.of(context);
    _tagController = TagScope.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_taskController.isInitialized) {
        _taskController.init();
      }
      if (!_tagController.isInitialized) {
        _tagController.init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppPalette.darkSurfaceElevated.withValues(alpha: 0.7),
        border: null,
        middle: Text('Statistics', style: theme.textTheme.navTitleTextStyle),
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
            top: -140,
            left: -60,
            child: _GlowSphere(size: 260, color: AppPalette.darkPrimary),
          ),
          Positioned(
            bottom: -120,
            right: -40,
            child: _GlowSphere(size: 220, color: AppPalette.darkPrimarySoft),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[
                _taskController,
                _tagController,
              ]),
              builder: (BuildContext context, Widget? _) {
                if (!_taskController.isInitialized || _taskController.isLoading) {
                  return const Center(child: CupertinoActivityIndicator());
                }
                final List<Task> tasks = _taskController.tasks;
                final List<Tag> tags = _tagController.tags;
                final _StatisticsSnapshot snapshot = _composeSnapshot(tasks, tags);
                final List<_MetricData> metrics = _buildMetrics(snapshot, theme);
                final List<_TagUsageData> topTagUsage = snapshot.tagUsages.take(5).toList();
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: Text(
                          'Overview',
                          style: theme.textTheme.textStyle.copyWith(
                            color: theme.primaryContrastingColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            return _MetricCard(metric: metrics[index]);
                          },
                          childCount: metrics.length,
                        ),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.98,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Text(
                          'Tag usage',
                          style: theme.textTheme.textStyle.copyWith(
                            color: theme.primaryContrastingColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        child: _TagBreakdownSection(
                          tagUsages: topTagUsage,
                          totalTasks: snapshot.totalTasks,
                        ),
                      ),
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

  _StatisticsSnapshot _composeSnapshot(List<Task> tasks, List<Tag> tags) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime weekAhead = today.add(const Duration(days: 7));
    int overdue = 0;
    int dueToday = 0;
    int upcoming = 0;
    int withoutDueDate = 0;
    double totalAgeDays = 0;
    final Map<String, Tag> tagIndex = <String, Tag>{
      for (final Tag tag in tags) tag.id: tag,
    };
    final Map<String, int> tagUsage = <String, int>{};
    for (final Task task in tasks) {
      totalAgeDays += now.difference(task.createdAt).inMinutes / 1440;
      final DateTime? due = task.dueDate;
      if (due == null) {
        withoutDueDate += 1;
      } else {
        final DateTime localDue = due.toLocal();
        final DateTime dueDate = DateTime(localDue.year, localDue.month, localDue.day);
        if (dueDate.isBefore(today)) {
          overdue += 1;
        } else if (dueDate.isAtSameMomentAs(today)) {
          dueToday += 1;
        } else if (!dueDate.isAfter(weekAhead)) {
          upcoming += 1;
        }
      }
      for (final String tagId in task.tagIds) {
        tagUsage[tagId] = (tagUsage[tagId] ?? 0) + 1;
      }
    }
    final List<_TagUsageData> tagUsages = <_TagUsageData>[];
    tagUsage.forEach((String id, int count) {
      final Tag? tag = tagIndex[id];
      if (tag != null) {
        tagUsages.add(_TagUsageData(tag: tag, count: count));
      }
    });
    tagUsages.sort(
      (_TagUsageData a, _TagUsageData b) => b.count.compareTo(a.count),
    );
    final double averageAgeDays = tasks.isEmpty ? 0 : totalAgeDays / tasks.length;
    return _StatisticsSnapshot(
      totalTasks: tasks.length,
      overdue: overdue,
      dueToday: dueToday,
      upcoming: upcoming,
      withoutDueDate: withoutDueDate,
      averageAgeDays: averageAgeDays,
      tagUsages: tagUsages,
    );
  }

  List<_MetricData> _buildMetrics(
    _StatisticsSnapshot snapshot,
    CupertinoThemeData theme,
  ) {
    final String averageFormatted = _formatAverageAge(snapshot.averageAgeDays);
    return <_MetricData>[
      _MetricData(
        label: 'Total tasks',
        value: snapshot.totalTasks.toString(),
        caption: 'All saved items',
        accent: theme.primaryColor,
      ),
      _MetricData(
        label: 'Overdue',
        value: snapshot.overdue.toString(),
        caption: 'Due before today',
        accent: AppPalette.darkGlow,
      ),
      _MetricData(
        label: 'Due today',
        value: snapshot.dueToday.toString(),
        caption: 'Scheduled for today',
        accent: AppPalette.darkPrimarySoft,
      ),
      _MetricData(
        label: 'Upcoming',
        value: snapshot.upcoming.toString(),
        caption: 'Next 7 days',
        accent: AppPalette.darkPrimary,
      ),
      _MetricData(
        label: 'No due date',
        value: snapshot.withoutDueDate.toString(),
        caption: 'Unscheduled items',
        accent: AppPalette.darkTextSecondary,
      ),
      _MetricData(
        label: 'Average age',
        value: averageFormatted,
        caption: 'Time since creation',
        accent: theme.primaryContrastingColor.withValues(alpha: 0.85),
      ),
    ];
  }

  String _formatAverageAge(double days) {
    if (days <= 0) {
      return '0d';
    }
    if (days >= 1) {
      final int decimals = days >= 10 ? 0 : 1;
      return '${days.toStringAsFixed(decimals)}d';
    }
    final double hours = days * 24;
    final int decimals = hours >= 10 ? 0 : 1;
    return '${hours.toStringAsFixed(decimals)}h';
  }
}

class _StatisticsSnapshot {
  const _StatisticsSnapshot({
    required this.totalTasks,
    required this.overdue,
    required this.dueToday,
    required this.upcoming,
    required this.withoutDueDate,
    required this.averageAgeDays,
    required this.tagUsages,
  });

  final int totalTasks;
  final int overdue;
  final int dueToday;
  final int upcoming;
  final int withoutDueDate;
  final double averageAgeDays;
  final List<_TagUsageData> tagUsages;
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.caption,
    required this.accent,
  });

  final String label;
  final String value;
  final String caption;
  final Color accent;
}

class _TagUsageData {
  const _TagUsageData({required this.tag, required this.count});

  final Tag tag;
  final int count;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    final TextStyle base = theme.textTheme.textStyle;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppPalette.cardGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: metric.accent.withValues(alpha: 0.45),
          width: 1.1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: metric.accent.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: metric.accent.withValues(alpha: 0.2),
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: metric.accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            metric.label,
            style: base.copyWith(
              color: theme.primaryContrastingColor.withValues(alpha: 0.88),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            metric.value,
            style: base.copyWith(
              color: theme.primaryContrastingColor,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metric.caption,
            style: base.copyWith(
              color: AppPalette.darkTextSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagBreakdownSection extends StatelessWidget {
  const _TagBreakdownSection({
    required this.tagUsages,
    required this.totalTasks,
  });

  final List<_TagUsageData> tagUsages;
  final int totalTasks;

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    final TextStyle base = theme.textTheme.textStyle;
    if (tagUsages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppPalette.cardGradient,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.35),
            width: 1.1,
          ),
        ),
        child: Text(
          totalTasks == 0
              ? 'Statistics will appear once tasks are added.'
              : 'Assign tags to tasks to see usage insights.',
          style: base.copyWith(
            color: AppPalette.darkTextSecondary,
            fontSize: 14,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppPalette.cardGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.35),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int index = 0; index < tagUsages.length; index += 1) ...<Widget>[
            if (index > 0) const SizedBox(height: 16),
            _TagUsageRow(
              usage: tagUsages[index],
              totalTasks: totalTasks,
            ),
          ],
        ],
      ),
    );
  }
}

class _TagUsageRow extends StatelessWidget {
  const _TagUsageRow({required this.usage, required this.totalTasks});

  final _TagUsageData usage;
  final int totalTasks;

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    final TextStyle base = theme.textTheme.textStyle;
    final double ratio = totalTasks == 0 ? 0 : usage.count / totalTasks;
    final double clampedRatio = ratio < 0
        ? 0
        : (ratio > 1 ? 1 : ratio);
    final int percent = (ratio * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: usage.tag.color.withValues(alpha: 0.22),
              ),
              child: Center(
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: usage.tag.color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                usage.tag.name,
                style: base.copyWith(
                  color: theme.primaryContrastingColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${usage.count}',
              style: base.copyWith(
                color: theme.primaryContrastingColor.withValues(alpha: 0.85),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 6,
                  color: AppPalette.darkTextSecondary.withValues(alpha: 0.16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: clampedRatio,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: usage.tag.color.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$percent%',
              style: base.copyWith(
                color: AppPalette.darkTextSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
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
