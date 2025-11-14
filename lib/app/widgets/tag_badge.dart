import 'package:flutter/cupertino.dart';
import 'package:pinco_mind_app/app/models/tag.dart';

class TagBadge extends StatelessWidget {
  const TagBadge({super.key, required this.tag, this.dense = false});

  final Tag tag;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    final Color baseColor = tag.color;
    final EdgeInsets padding = dense
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    final double fontSize = dense ? 12 : 13;
    final double dotSize = dense ? 6 : 8;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            baseColor.withValues(alpha: 0.35),
            baseColor.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: baseColor.withValues(alpha: 0.5)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: baseColor.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: dotSize,
            height: dotSize,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle),
          ),
          Text(
            tag.name,
            style: theme.textTheme.textStyle.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: theme.primaryContrastingColor,
            ),
          ),
        ],
      ),
    );
  }
}
