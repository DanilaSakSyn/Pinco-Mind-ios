import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:pinco_mind_app/app/tag_controller.dart';
import 'package:pinco_mind_app/app/theme_controller.dart';
import 'package:pinco_mind_app/app/models/tag.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const List<Color> _palette = <Color>[
    Color(0xFF7C4DFF),
    Color(0xFFFF6F61),
    Color(0xFF4DD0E1),
    Color(0xFFFFCA28),
    Color(0xFF26C6DA),
    Color(0xFF66BB6A),
  ];

  static const String _appTitle = 'Pinco Mind';
  static const String _appVersion = '1.0.0';
  static const String _appDescription = 'Focus on mindful productivity.';
  static const String _developerName = 'SHADY BETH MARTINEZ';
  static const String _developerContact = 'shadybeth11909@icloud.com';
  static const String _privacyPolicyTitle = 'Privacy Policy';
  static const String _privacyPolicySummary =
      'Read more about how we handle your data at pincomind.app/privacy.';
  static const String _privacyPolicyLink =
      'https://pincomind.com/privacy-policy.html';

  late final TextEditingController _tagNameController;
  late Color _selectedColor;
  late TagController _tagController;

  @override
  void initState() {
    super.initState();
    _tagNameController = TextEditingController();
    _selectedColor = _palette.first;
  }

  @override
  void dispose() {
    _tagNameController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tagController = TagScope.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_tagController.isInitialized) {
        _tagController.init();
      }
    });
  }

  bool get _canCreateTag => _tagNameController.text.trim().isNotEmpty;

  Future<void> _handleCreateTag() async {
    if (!_canCreateTag) {
      return;
    }
    await _tagController.createTag(
      name: _tagNameController.text.trim(),
      color: _selectedColor,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _tagNameController.clear();
      _selectedColor = _palette.first;
    });
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  Future<void> _showEditTagDialog(Tag tag) async {
    final TextEditingController controller = TextEditingController(
      text: tag.name,
    );
    Color tempColor = tag.color;

    final bool? saved = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final bool canSave = controller.text.trim().isNotEmpty;
            return CupertinoAlertDialog(
              title: const Text('Edit Tag'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: controller,
                    placeholder: 'Tag name',
                    cursorColor: CupertinoTheme.of(context).primaryColor,
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Color',
                    style:
                        CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CupertinoTheme.of(
                                context,
                              ).primaryContrastingColor,
                            ),
                  ),
                  const SizedBox(height: 10),
                  _buildColorPicker(
                    selected: tempColor,
                    onSelect: (Color color) =>
                        setModalState(() => tempColor = color),
                  ),
                ],
              ),
              actions: <Widget>[
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: canSave
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      await _tagController.updateTag(
        tag.id,
        name: controller.text.trim(),
        color: tempColor,
      );
    }
    controller.dispose();
  }

  Future<void> _confirmDeleteTag(Tag tag) async {
    final bool? shouldDelete = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Delete Tag'),
          content: Text('Remove "${tag.name}"?'),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _tagController.deleteTag(tag.id);
    }
  }

  Future<void> _showPrivacyPolicy() async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final CupertinoThemeData dialogTheme = CupertinoTheme.of(dialogContext);
        return CupertinoAlertDialog(
          title: Text(_privacyPolicyTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 12),
              Text(
                _privacyPolicySummary,
                style: dialogTheme.textTheme.textStyle.copyWith(
                  fontSize: 13,
                  color: dialogTheme.primaryContrastingColor.withValues(
                    alpha: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _privacyPolicyLink,
                style: dialogTheme.textTheme.textStyle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: dialogTheme.primaryColor,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColorPicker({
    required Color selected,
    required ValueChanged<Color> onSelect,
  }) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _palette.map((Color color) {
        final bool isSelected = color == selected;
        return GestureDetector(
          onTap: () => onSelect(color),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: theme.primaryContrastingColor, width: 2)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = ThemeScope.of(context);
    final ThemeMode selectedMode = themeController.mode;
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    final TextStyle baseStyle = theme.textTheme.textStyle;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppPalette.darkSurfaceElevated.withOpacity(0.7),
        border: null,
        middle: const Text('Settings'),
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
            left: -80,
            child: _GlowSphere(size: 260, color: AppPalette.darkPrimary),
          ),
          Positioned(
            bottom: -120,
            right: -60,
            child: _GlowSphere(size: 220, color: AppPalette.darkPrimarySoft),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: <Widget>[
                const SizedBox(height: 24),
                Text(
                  'Tags',
                  style: baseStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryContrastingColor,
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _tagController,
                  builder: (BuildContext context, Widget? _) {
                    if (!_tagController.isInitialized ||
                        _tagController.isLoading) {
                      return const Center(child: CupertinoActivityIndicator());
                    }
                    final List<Tag> tags = _tagController.tags;
                    if (tags.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          'Create tags to organise tasks later.',
                          style: baseStyle.copyWith(
                            fontSize: 13,
                            color: theme.primaryContrastingColor.withValues(
                              alpha: 0.65,
                            ),
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: tags
                            .map(
                              (Tag tag) => _TagTile(
                                tag: tag,
                                onEdit: () => _showEditTagDialog(tag),
                                onDelete: () => _confirmDeleteTag(tag),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppPalette.cardGradient,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.28),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: theme.primaryColor.withValues(alpha: 0.16),
                        blurRadius: 20,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'New Tag',
                        style: baseStyle.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryContrastingColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CupertinoTextField(
                        controller: _tagNameController,
                        placeholder: 'Tag name',
                        cursorColor: theme.primaryColor,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Color',
                        style: baseStyle.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryContrastingColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildColorPicker(
                        selected: _selectedColor,
                        onSelect: (Color color) {
                          setState(() => _selectedColor = color);
                        },
                      ),
                      const SizedBox(height: 16),
                      CupertinoButton.filled(
                        onPressed: _canCreateTag ? _handleCreateTag : null,
                        child: const Text('Create Tag'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Application',
                  style: baseStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryContrastingColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppPalette.cardGradient,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.28),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: theme.primaryColor.withValues(alpha: 0.16),
                        blurRadius: 20,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Name',
                        style: baseStyle.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryContrastingColor.withValues(
                            alpha: 0.9,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _appTitle,
                        style: baseStyle.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryContrastingColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Version',
                        style: baseStyle.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryContrastingColor.withValues(
                            alpha: 0.9,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _appVersion,
                        style: baseStyle.copyWith(
                          fontSize: 13,
                          color: theme.primaryContrastingColor.withValues(
                            alpha: 0.72,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _appDescription,
                        style: baseStyle.copyWith(
                          fontSize: 13,
                          color: theme.primaryContrastingColor.withValues(
                            alpha: 0.72,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Developer',
                  style: baseStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryContrastingColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppPalette.cardGradient,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.28),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: theme.primaryColor.withValues(alpha: 0.16),
                        blurRadius: 20,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _developerName,
                        style: baseStyle.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryContrastingColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _developerContact,
                        style: baseStyle.copyWith(
                          fontSize: 13,
                          color: theme.primaryContrastingColor.withValues(
                            alpha: 0.72,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        onPressed: () {
                          _launchUrl(_privacyPolicyLink);
                        },
                        child: Text(_privacyPolicyTitle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      child: Text(
        text,
        style: theme.textTheme.textStyle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: theme.primaryContrastingColor,
        ),
      ),
    );
  }
}

class _TagTile extends StatelessWidget {
  const _TagTile({
    required this.tag,
    required this.onEdit,
    required this.onDelete,
  });

  final Tag tag;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    final TextStyle base = theme.textTheme.textStyle;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            tag.color.withValues(alpha: 0.32),
            tag.color.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tag.color.withValues(alpha: 0.45)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: tag.color.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: tag.color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tag.name,
              style: base.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.primaryContrastingColor,
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 28,
            onPressed: onEdit,
            child: Icon(
              CupertinoIcons.pencil,
              size: 18,
              color: theme.primaryContrastingColor,
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 28,
            onPressed: onDelete,
            child: const Icon(
              CupertinoIcons.delete,
              size: 18,
              color: CupertinoColors.systemRed,
            ),
          ),
        ],
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
